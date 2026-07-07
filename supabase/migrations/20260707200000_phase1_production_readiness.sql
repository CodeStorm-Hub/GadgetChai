-- Phase 1: Production readiness — address, referrals, checkout groups, KYC limits, payment events

-- ---------------------------------------------------------------------------
-- Profile extensions
-- ---------------------------------------------------------------------------

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS delivery_address text,
  ADD COLUMN IF NOT EXISTS emergency_contact text,
  ADD COLUMN IF NOT EXISTS referral_code text,
  ADD COLUMN IF NOT EXISTS referred_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_referral_code
  ON public.profiles(referral_code)
  WHERE referral_code IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Rental checkout extensions
-- ---------------------------------------------------------------------------

ALTER TABLE public.rentals
  ADD COLUMN IF NOT EXISTS care_plus_monthly numeric(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS delivery_fee numeric(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS selected_color text,
  ADD COLUMN IF NOT EXISTS checkout_group_id uuid;

CREATE INDEX IF NOT EXISTS idx_rentals_checkout_group
  ON public.rentals(checkout_group_id)
  WHERE checkout_group_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- KYC session tracking (BFIU: 10 tries/session, 2 sessions/day, 3 total)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.kyc_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  session_date date NOT NULL DEFAULT CURRENT_DATE,
  attempt_count integer NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, session_date)
);

CREATE INDEX IF NOT EXISTS idx_kyc_sessions_user_id ON public.kyc_sessions(user_id);

-- ---------------------------------------------------------------------------
-- Referral program
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  referee_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  referral_code text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'credited', 'expired')),
  credit_amount numeric(12,2) NOT NULL DEFAULT 500,
  credited_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referee ON public.referrals(referee_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_referrals_referee_unique
  ON public.referrals(referee_id)
  WHERE referee_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- bKash async payment event log (IPN / reconciliation)
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.bkash_payment_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id uuid REFERENCES public.rentals(id) ON DELETE SET NULL,
  payment_id text,
  trx_id text,
  event_type text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}',
  processed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bkash_events_rental ON public.bkash_payment_events(rental_id);
CREATE INDEX IF NOT EXISTS idx_bkash_events_payment ON public.bkash_payment_events(payment_id);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.generate_referral_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  candidate text;
BEGIN
  LOOP
    candidate := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE referral_code = candidate
    );
  END LOOP;
  RETURN candidate;
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_profile_referral_code()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.referral_code IS NULL OR NEW.referral_code = '' THEN
    NEW.referral_code := public.generate_referral_code();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_referral_code ON public.profiles;
CREATE TRIGGER trg_profiles_referral_code
  BEFORE INSERT OR UPDATE OF referral_code ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.ensure_profile_referral_code();

-- Backfill referral codes for existing profiles
UPDATE public.profiles
SET referral_code = public.generate_referral_code()
WHERE referral_code IS NULL OR referral_code = '';

-- ---------------------------------------------------------------------------
-- KYC attempt limits (callable from ML worker via service role)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.check_and_record_kyc_attempt(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_sessions integer;
  v_today_sessions integer;
  v_attempt_count integer;
  v_session_id uuid;
BEGIN
  SELECT count(*)::integer INTO v_total_sessions
  FROM public.kyc_sessions
  WHERE user_id = p_user_id;

  IF v_total_sessions >= 3 THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'Maximum 3 KYC sessions reached. Please contact support for manual verification.'
    );
  END IF;

  SELECT count(*)::integer INTO v_today_sessions
  FROM public.kyc_sessions
  WHERE user_id = p_user_id AND session_date = CURRENT_DATE;

  IF v_today_sessions >= 2 AND NOT EXISTS (
    SELECT 1 FROM public.kyc_sessions
    WHERE user_id = p_user_id AND session_date = CURRENT_DATE
  ) THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'Maximum 2 KYC sessions per day. Please try again tomorrow.'
    );
  END IF;

  INSERT INTO public.kyc_sessions (user_id, session_date, attempt_count)
  VALUES (p_user_id, CURRENT_DATE, 1)
  ON CONFLICT (user_id, session_date)
  DO UPDATE SET
    attempt_count = public.kyc_sessions.attempt_count + 1,
    updated_at = now()
  RETURNING attempt_count, id INTO v_attempt_count, v_session_id;

  IF v_attempt_count > 10 THEN
    RETURN jsonb_build_object(
      'allowed', false,
      'reason', 'Maximum 10 attempts per session. Start a new session tomorrow or contact support.',
      'attempts', v_attempt_count
    );
  END IF;

  RETURN jsonb_build_object(
    'allowed', true,
    'attempts', v_attempt_count,
    'session_id', v_session_id
  );
END;
$$;

-- ---------------------------------------------------------------------------
-- Admin KYC review — sync profile status + trust score
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.review_kyc(
  p_review_id uuid,
  p_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_similarity numeric;
  v_kyc_status text;
  v_trust_score integer;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden: admin only';
  END IF;

  IF p_status NOT IN ('approved', 'rejected', 'pending') THEN
    RAISE EXCEPTION 'Invalid status: %', p_status;
  END IF;

  UPDATE public.kyc_reviews
  SET status = p_status, updated_at = now()
  WHERE id = p_review_id
  RETURNING user_id, similarity_score INTO v_user_id, v_similarity;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'KYC review not found';
  END IF;

  v_kyc_status := CASE p_status
    WHEN 'approved' THEN 'verified'
    WHEN 'rejected' THEN 'rejected'
    ELSE 'pending'
  END;

  v_trust_score := CASE p_status
    WHEN 'approved' THEN greatest(80, coalesce(v_similarity * 100, 80)::integer)
    WHEN 'rejected' THEN 20
    ELSE 50
  END;

  UPDATE public.profiles
  SET
    kyc_status = v_kyc_status,
    trust_score = v_trust_score,
    updated_at = now()
  WHERE id = v_user_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- Referral: apply code on signup (idempotent per referee)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.apply_referral_code(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_referrer_id uuid;
  v_normalized text := upper(trim(p_code));
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id INTO v_referrer_id
  FROM public.profiles
  WHERE referral_code = v_normalized;

  IF v_referrer_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid referral code');
  END IF;

  IF v_referrer_id = v_user_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'You cannot use your own code');
  END IF;

  IF EXISTS (SELECT 1 FROM public.referrals WHERE referee_id = v_user_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Referral already applied');
  END IF;

  UPDATE public.profiles SET referred_by = v_referrer_id WHERE id = v_user_id;

  INSERT INTO public.referrals (referrer_id, referee_id, referral_code, status)
  VALUES (v_referrer_id, v_user_id, v_normalized, 'pending');

  RETURN jsonb_build_object('success', true, 'referrer_id', v_referrer_id);
END;
$$;

-- ---------------------------------------------------------------------------
-- Checkout group total for bKash initial charge
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.checkout_group_initial_total(p_group_id uuid)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(sum(monthly_price + care_plus_monthly), 0)
       + coalesce(max(security_deposit), 0)
       + coalesce(max(delivery_fee), 0)
  FROM public.rentals
  WHERE checkout_group_id = p_group_id
    AND status = 'pending_kyc';
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE public.kyc_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bkash_payment_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS kyc_sessions_select_own ON public.kyc_sessions;
CREATE POLICY kyc_sessions_select_own ON public.kyc_sessions
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS referrals_select_own ON public.referrals;
CREATE POLICY referrals_select_own ON public.referrals
  FOR SELECT TO authenticated
  USING (referrer_id = auth.uid() OR referee_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS bkash_events_admin ON public.bkash_payment_events;
CREATE POLICY bkash_events_admin ON public.bkash_payment_events
  FOR SELECT TO authenticated
  USING (public.is_admin());

GRANT EXECUTE ON FUNCTION public.check_and_record_kyc_attempt(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.review_kyc(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.apply_referral_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.checkout_group_initial_total(uuid) TO service_role;
