-- Phase 3: Growth & differentiation — reviews, discounts, B2B, sustainability

-- ---------------------------------------------------------------------------
-- Profile discount programs
-- ---------------------------------------------------------------------------

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS account_type text NOT NULL DEFAULT 'consumer'
    CHECK (account_type IN ('consumer', 'student', 'corporate')),
  ADD COLUMN IF NOT EXISTS discount_percent numeric(5,2) NOT NULL DEFAULT 0
    CHECK (discount_percent >= 0 AND discount_percent <= 50),
  ADD COLUMN IF NOT EXISTS student_id_number text,
  ADD COLUMN IF NOT EXISTS corporate_name text,
  ADD COLUMN IF NOT EXISTS locale text NOT NULL DEFAULT 'en'
    CHECK (locale IN ('en', 'bn'));

-- ---------------------------------------------------------------------------
-- Device reviews (post-return)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.device_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id uuid NOT NULL UNIQUE REFERENCES public.rentals(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_id uuid NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_device_reviews_device ON public.device_reviews(device_id);
CREATE INDEX IF NOT EXISTS idx_device_reviews_user ON public.device_reviews(user_id);

-- ---------------------------------------------------------------------------
-- B2B fleet inquiries
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.b2b_inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  company_name text NOT NULL,
  contact_name text NOT NULL,
  contact_phone text NOT NULL,
  contact_email text,
  device_count integer NOT NULL CHECK (device_count > 0),
  device_types text[] NOT NULL DEFAULT '{}',
  notes text,
  status text NOT NULL DEFAULT 'submitted'
    CHECK (status IN ('submitted', 'contacted', 'quoted', 'closed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_b2b_inquiries_status ON public.b2b_inquiries(status);

-- ---------------------------------------------------------------------------
-- Payment method preference on rentals
-- ---------------------------------------------------------------------------

ALTER TABLE public.rentals
  ADD COLUMN IF NOT EXISTS payment_method text NOT NULL DEFAULT 'bkash'
    CHECK (payment_method IN ('bkash', 'nagad'));

-- ---------------------------------------------------------------------------
-- Submit device review (one per returned rental)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.submit_device_review(
  p_rental_id uuid,
  p_rating integer,
  p_review_text text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rental record;
BEGIN
  IF p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION 'Rating must be between 1 and 5';
  END IF;

  SELECT * INTO v_rental
  FROM public.rentals
  WHERE id = p_rental_id
    AND user_id = auth.uid()
    AND status = 'returned';

  IF v_rental IS NULL THEN
    RAISE EXCEPTION 'Returned rental not found';
  END IF;

  IF EXISTS (SELECT 1 FROM public.device_reviews WHERE rental_id = p_rental_id) THEN
    RAISE EXCEPTION 'Review already submitted for this rental';
  END IF;

  INSERT INTO public.device_reviews (rental_id, user_id, device_id, rating, review_text)
  VALUES (p_rental_id, auth.uid(), v_rental.device_id, p_rating, p_review_text);

  RETURN jsonb_build_object('success', true, 'device_id', v_rental.device_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- Apply student / corporate discount program
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.apply_discount_program(
  p_account_type text,
  p_identifier text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_discount numeric;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_account_type NOT IN ('student', 'corporate') THEN
    RAISE EXCEPTION 'Invalid account type';
  END IF;

  IF p_identifier IS NULL OR trim(p_identifier) = '' THEN
    RAISE EXCEPTION 'Student ID or company name is required';
  END IF;

  v_discount := CASE p_account_type
    WHEN 'student' THEN 10
    WHEN 'corporate' THEN 15
    ELSE 0
  END;

  UPDATE public.profiles
  SET
    account_type = p_account_type,
    discount_percent = v_discount,
    student_id_number = CASE WHEN p_account_type = 'student' THEN trim(p_identifier) ELSE student_id_number END,
    corporate_name = CASE WHEN p_account_type = 'corporate' THEN trim(p_identifier) ELSE corporate_name END,
    updated_at = now()
  WHERE id = auth.uid();

  RETURN jsonb_build_object(
    'success', true,
    'account_type', p_account_type,
    'discount_percent', v_discount
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Device rating aggregate
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.device_rating_summary(p_device_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'avg_rating', coalesce(round(avg(rating)::numeric, 1), 0),
    'review_count', count(*)::integer
  )
  FROM public.device_reviews
  WHERE device_id = p_device_id;
$$;

-- ---------------------------------------------------------------------------
-- User sustainability stats (circular economy)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.user_sustainability_stats(p_user_id uuid DEFAULT auth.uid())
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'completed_rentals', count(*) FILTER (WHERE status IN ('returned', 'active')),
    'estimated_co2_kg_saved', (count(*) FILTER (WHERE status IN ('returned', 'active')) * 42)::integer,
    'devices_kept_active', count(DISTINCT device_id)
  )
  FROM public.rentals
  WHERE user_id = coalesce(p_user_id, auth.uid());
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE public.device_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.b2b_inquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS device_reviews_select_all ON public.device_reviews;
CREATE POLICY device_reviews_select_all ON public.device_reviews
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS device_reviews_insert_own ON public.device_reviews;
CREATE POLICY device_reviews_insert_own ON public.device_reviews
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS b2b_inquiries_insert ON public.b2b_inquiries;
CREATE POLICY b2b_inquiries_insert ON public.b2b_inquiries
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

DROP POLICY IF EXISTS b2b_inquiries_select_own ON public.b2b_inquiries;
CREATE POLICY b2b_inquiries_select_own ON public.b2b_inquiries
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

GRANT EXECUTE ON FUNCTION public.submit_device_review(uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.apply_discount_program(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.device_rating_summary(uuid) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.user_sustainability_stats(uuid) TO authenticated;
