-- GadgetChai security hardening: RLS cleanup, grants, storage, indexes

-- ---------------------------------------------------------------------------
-- Fix set_updated_at search_path
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Revoke public RPC on SECURITY DEFINER helpers (trigger / RLS only)
-- ---------------------------------------------------------------------------

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Drop legacy duplicate RLS policies
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Public profiles are readable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can view devices" ON public.devices;
DROP POLICY IF EXISTS "Admins can manage devices" ON public.devices;
DROP POLICY IF EXISTS "Admins can manage device items" ON public.device_items;
DROP POLICY IF EXISTS "Users can view items they rented" ON public.device_items;
DROP POLICY IF EXISTS "Admins can view and manage all rentals" ON public.rentals;
DROP POLICY IF EXISTS "Users can create rentals" ON public.rentals;
DROP POLICY IF EXISTS "Users can view their own rentals" ON public.rentals;
DROP POLICY IF EXISTS "Admins can view and manage all kyc_reviews" ON public.kyc_reviews;
DROP POLICY IF EXISTS "Users can insert their own kyc_reviews" ON public.kyc_reviews;
DROP POLICY IF EXISTS "Users can view their own kyc_reviews" ON public.kyc_reviews;

-- device_items: allow renters to see their assigned unit
DROP POLICY IF EXISTS device_items_select_rented ON public.device_items;
CREATE POLICY device_items_select_rented ON public.device_items
  FOR SELECT USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.rentals r
      WHERE r.device_item_id = device_items.id AND r.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- Transactions RLS (admin + own via rental)
-- ---------------------------------------------------------------------------

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions;
DROP POLICY IF EXISTS transactions_select_own ON public.transactions;
CREATE POLICY transactions_select_own ON public.transactions
  FOR SELECT USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.rentals r
      WHERE r.id = transactions.rental_id AND r.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- Recurring billing retry counter
-- ---------------------------------------------------------------------------

ALTER TABLE public.rentals
  ADD COLUMN IF NOT EXISTS billing_retry_count integer NOT NULL DEFAULT 0;

-- ---------------------------------------------------------------------------
-- Performance: FK indexes
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_device_items_device_id ON public.device_items(device_id);
CREATE INDEX IF NOT EXISTS idx_rentals_device_id ON public.rentals(device_id);
CREATE INDEX IF NOT EXISTS idx_rentals_device_item_id ON public.rentals(device_item_id);
CREATE INDEX IF NOT EXISTS idx_transactions_rental_id ON public.transactions(rental_id);
CREATE INDEX IF NOT EXISTS idx_kyc_reviews_user_id ON public.kyc_reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_rentals_next_billing_date ON public.rentals(next_billing_date)
  WHERE status = 'active';

-- ---------------------------------------------------------------------------
-- Tighten GRANTs (defense in depth; RLS remains primary)
-- ---------------------------------------------------------------------------

REVOKE ALL ON public.devices FROM authenticated;
REVOKE ALL ON public.device_items FROM authenticated;
REVOKE ALL ON public.promos FROM authenticated;
REVOKE ALL ON public.categories FROM authenticated;
REVOKE ALL ON public.damage_reports FROM authenticated;

GRANT SELECT ON public.devices TO anon, authenticated;
GRANT SELECT ON public.promos TO anon, authenticated;
GRANT SELECT ON public.categories TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.rentals TO authenticated;
GRANT SELECT, INSERT ON public.damage_reports TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.kyc_reviews TO authenticated;
GRANT SELECT ON public.device_items TO authenticated;
GRANT SELECT ON public.transactions TO authenticated;

-- ---------------------------------------------------------------------------
-- Storage: private damage-reports + kyc-documents buckets
-- ---------------------------------------------------------------------------

UPDATE storage.buckets SET public = false WHERE id = 'damage-reports';

INSERT INTO storage.buckets (id, name, public)
VALUES ('kyc-documents', 'kyc-documents', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS damage_reports_storage_select ON storage.objects;
CREATE POLICY damage_reports_storage_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'damage-reports'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
    )
  );

DROP POLICY IF EXISTS damage_reports_storage_insert ON storage.objects;
CREATE POLICY damage_reports_storage_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'damage-reports'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS kyc_documents_storage_insert ON storage.objects;
CREATE POLICY kyc_documents_storage_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'kyc-documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS kyc_documents_storage_select ON storage.objects;
CREATE POLICY kyc_documents_storage_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'kyc-documents'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      OR public.is_admin()
    )
  );
