-- GadgetChai schema extensions, RLS policies, and auth triggers

-- ---------------------------------------------------------------------------
-- Column extensions on existing tables
-- ---------------------------------------------------------------------------

ALTER TABLE public.devices
  ADD COLUMN IF NOT EXISTS specs_memory text,
  ADD COLUMN IF NOT EXISTS specs_battery text,
  ADD COLUMN IF NOT EXISTS specs_display text,
  ADD COLUMN IF NOT EXISTS specs_processor text,
  ADD COLUMN IF NOT EXISTS specs_camera text,
  ADD COLUMN IF NOT EXISTS is_featured boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.device_items
  ADD COLUMN IF NOT EXISTS cumulative_revenue numeric(12,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.rentals
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.kyc_reviews
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- ---------------------------------------------------------------------------
-- Home content tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.promos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  bg_color text NOT NULL DEFAULT '#1E293B',
  text_color text NOT NULL DEFAULT '#FFFFFF',
  image_url text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL UNIQUE,
  image_url text,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.damage_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id uuid NOT NULL REFERENCES public.rentals(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  description text NOT NULL,
  photo_url text,
  status text NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'reviewing', 'resolved')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_damage_reports_rental_id ON public.damage_reports(rental_id);
CREATE INDEX IF NOT EXISTS idx_damage_reports_user_id ON public.damage_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_is_featured ON public.devices(is_featured, sort_order);
CREATE INDEX IF NOT EXISTS idx_rentals_user_id ON public.rentals(user_id);
CREATE INDEX IF NOT EXISTS idx_rentals_status ON public.rentals(status);
CREATE INDEX IF NOT EXISTS idx_kyc_reviews_status ON public.kyc_reviews(status);

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, role, phone, full_name, kyc_status, trust_score)
  VALUES (
    NEW.id,
    'customer',
    NEW.phone,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', ''),
    'pending',
    50
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'devices', 'device_items', 'rentals', 'kyc_reviews', 'profiles',
    'promos', 'categories', 'damage_reports'
  ]
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS set_%I_updated_at ON public.%I', tbl, tbl);
    EXECUTE format(
      'CREATE TRIGGER set_%I_updated_at BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()',
      tbl, tbl
    );
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------

ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kyc_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.damage_reports ENABLE ROW LEVEL SECURITY;

-- devices
DROP POLICY IF EXISTS devices_select_public ON public.devices;
CREATE POLICY devices_select_public ON public.devices
  FOR SELECT USING (true);

DROP POLICY IF EXISTS devices_admin_all ON public.devices;
CREATE POLICY devices_admin_all ON public.devices
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- profiles
DROP POLICY IF EXISTS profiles_select_own ON public.profiles;
CREATE POLICY profiles_select_own ON public.profiles
  FOR SELECT USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (auth.uid() = id OR public.is_admin())
  WITH CHECK (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id OR public.is_admin());

-- rentals
DROP POLICY IF EXISTS rentals_select_own ON public.rentals;
CREATE POLICY rentals_select_own ON public.rentals
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS rentals_insert_own ON public.rentals;
CREATE POLICY rentals_insert_own ON public.rentals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS rentals_update_own ON public.rentals;
CREATE POLICY rentals_update_own ON public.rentals
  FOR UPDATE USING (auth.uid() = user_id OR public.is_admin())
  WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- device_items
DROP POLICY IF EXISTS device_items_select_admin ON public.device_items;
CREATE POLICY device_items_select_admin ON public.device_items
  FOR SELECT USING (public.is_admin());

DROP POLICY IF EXISTS device_items_admin_all ON public.device_items;
CREATE POLICY device_items_admin_all ON public.device_items
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- kyc_reviews
DROP POLICY IF EXISTS kyc_reviews_select_own ON public.kyc_reviews;
CREATE POLICY kyc_reviews_select_own ON public.kyc_reviews
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS kyc_reviews_insert_own ON public.kyc_reviews;
CREATE POLICY kyc_reviews_insert_own ON public.kyc_reviews
  FOR INSERT WITH CHECK (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS kyc_reviews_update_admin ON public.kyc_reviews;
CREATE POLICY kyc_reviews_update_admin ON public.kyc_reviews
  FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

-- promos & categories (public read)
DROP POLICY IF EXISTS promos_select_public ON public.promos;
CREATE POLICY promos_select_public ON public.promos
  FOR SELECT USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS promos_admin_all ON public.promos;
CREATE POLICY promos_admin_all ON public.promos
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS categories_select_public ON public.categories;
CREATE POLICY categories_select_public ON public.categories
  FOR SELECT USING (is_active = true OR public.is_admin());

DROP POLICY IF EXISTS categories_admin_all ON public.categories;
CREATE POLICY categories_admin_all ON public.categories
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- damage_reports
DROP POLICY IF EXISTS damage_reports_select_own ON public.damage_reports;
CREATE POLICY damage_reports_select_own ON public.damage_reports
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS damage_reports_insert_own ON public.damage_reports;
CREATE POLICY damage_reports_insert_own ON public.damage_reports
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS damage_reports_update_admin ON public.damage_reports;
CREATE POLICY damage_reports_update_admin ON public.damage_reports
  FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Grants for API roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.devices TO anon, authenticated;
GRANT SELECT ON public.promos TO anon, authenticated;
GRANT SELECT ON public.categories TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.rentals TO authenticated;
GRANT SELECT, INSERT ON public.damage_reports TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.kyc_reviews TO authenticated;
GRANT ALL ON public.device_items TO authenticated;
GRANT ALL ON public.devices TO authenticated;
GRANT ALL ON public.promos TO authenticated;
GRANT ALL ON public.categories TO authenticated;
GRANT ALL ON public.damage_reports TO authenticated;

-- Storage bucket for damage report photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('damage-reports', 'damage-reports', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS damage_reports_storage_insert ON storage.objects;
CREATE POLICY damage_reports_storage_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'damage-reports' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS damage_reports_storage_select ON storage.objects;
CREATE POLICY damage_reports_storage_select ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'damage-reports');
