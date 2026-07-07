-- Phase 2: Revenue & retention — extend rental, scheduled returns, wishlist, damage admin

-- ---------------------------------------------------------------------------
-- Rental lifecycle extensions
-- ---------------------------------------------------------------------------

ALTER TABLE public.rentals
  ADD COLUMN IF NOT EXISTS return_pickup_date timestamptz,
  ADD COLUMN IF NOT EXISTS extended_months integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS extension_requested_at timestamptz;

-- ---------------------------------------------------------------------------
-- Wishlist / favorites
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.wishlist_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_id uuid NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, device_id)
);

CREATE INDEX IF NOT EXISTS idx_wishlist_user ON public.wishlist_items(user_id);

-- ---------------------------------------------------------------------------
-- Extend rental (add months, recalculate end_date)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.extend_rental(p_rental_id uuid, p_extra_months integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rental record;
  v_new_end timestamptz;
BEGIN
  IF p_extra_months NOT IN (1, 3, 6) THEN
    RAISE EXCEPTION 'Extension must be 1, 3, or 6 months';
  END IF;

  SELECT * INTO v_rental
  FROM public.rentals
  WHERE id = p_rental_id AND user_id = auth.uid() AND status = 'active';

  IF v_rental IS NULL THEN
    RAISE EXCEPTION 'Active rental not found';
  END IF;

  v_new_end := coalesce(v_rental.end_date, now()) + (p_extra_months || ' months')::interval;

  UPDATE public.rentals
  SET
    end_date = v_new_end,
    plan_months = plan_months + p_extra_months,
    extended_months = extended_months + p_extra_months,
    extension_requested_at = now(),
    updated_at = now()
  WHERE id = p_rental_id;

  RETURN jsonb_build_object(
    'rental_id', p_rental_id,
    'new_end_date', v_new_end,
    'extra_months', p_extra_months
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Schedule return with pickup date
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.schedule_rental_return(
  p_rental_id uuid,
  p_pickup_date timestamptz
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rental record;
BEGIN
  IF p_pickup_date < now() THEN
    RAISE EXCEPTION 'Pickup date must be in the future';
  END IF;

  SELECT * INTO v_rental
  FROM public.rentals
  WHERE id = p_rental_id
    AND user_id = auth.uid()
    AND status IN ('active', 'in_transit');

  IF v_rental IS NULL THEN
    RAISE EXCEPTION 'Rental not eligible for return scheduling';
  END IF;

  UPDATE public.rentals
  SET
    return_pickup_date = p_pickup_date,
    status = 'returned',
    updated_at = now()
  WHERE id = p_rental_id;

  RETURN jsonb_build_object('rental_id', p_rental_id, 'pickup_date', p_pickup_date);
END;
$$;

-- ---------------------------------------------------------------------------
-- Admin: review damage report
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.review_damage_report(
  p_report_id uuid,
  p_status text,
  p_admin_notes text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden: admin only';
  END IF;

  IF p_status NOT IN ('reviewing', 'resolved') THEN
    RAISE EXCEPTION 'Invalid status';
  END IF;

  UPDATE public.damage_reports
  SET
    status = p_status,
    description = CASE
      WHEN p_admin_notes IS NOT NULL AND p_admin_notes <> ''
      THEN description || E'\n\n[Admin] ' || p_admin_notes
      ELSE description
    END,
    updated_at = now()
  WHERE id = p_report_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- MRR trend (last 6 months from transactions)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.admin_mrr_trend(p_months integer DEFAULT 6)
RETURNS TABLE(month_label text, mrr numeric)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH months AS (
    SELECT generate_series(
      date_trunc('month', now()) - ((p_months - 1) || ' months')::interval,
      date_trunc('month', now()),
      '1 month'::interval
    ) AS month_start
  ),
  active_mrr AS (
    SELECT date_trunc('month', now()) AS month_start,
           coalesce(sum(monthly_price + care_plus_monthly), 0) AS mrr
    FROM public.rentals
    WHERE status = 'active'
  )
  SELECT
    to_char(m.month_start, 'Mon') AS month_label,
    coalesce(
      (SELECT sum(t.amount) FROM public.transactions t
       WHERE t.status = 'success'
         AND date_trunc('month', t.created_at) = m.month_start),
      (SELECT a.mrr FROM active_mrr a WHERE m.month_start = date_trunc('month', now())),
      0
    )::numeric AS mrr
  FROM months m
  ORDER BY m.month_start;
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE public.wishlist_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS wishlist_select_own ON public.wishlist_items;
CREATE POLICY wishlist_select_own ON public.wishlist_items
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS wishlist_insert_own ON public.wishlist_items;
CREATE POLICY wishlist_insert_own ON public.wishlist_items
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS wishlist_delete_own ON public.wishlist_items;
CREATE POLICY wishlist_delete_own ON public.wishlist_items
  FOR DELETE TO authenticated USING (user_id = auth.uid());

GRANT EXECUTE ON FUNCTION public.extend_rental(uuid, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.schedule_rental_return(uuid, timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.review_damage_report(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_mrr_trend(integer) TO authenticated;
