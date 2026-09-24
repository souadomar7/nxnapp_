-- ==============================================================================
-- 002_PROFILES_ROLES.SQL
-- Extended user profiles, RBAC roles, and authorization helpers.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name       TEXT,
  phone           TEXT,
  avatar_url      TEXT,
  role            TEXT NOT NULL DEFAULT 'merchant'
                    CHECK (role IN ('guest', 'merchant', 'operations_admin',
                                    'kyc_admin', 'finance_admin', 'warehouse_admin',
                                    'super_admin')),
  status          TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'suspended', 'pending_verification')),
  kyc_status      TEXT NOT NULL DEFAULT 'not_submitted'
                    CHECK (kyc_status IN ('not_submitted', 'pending', 'under_review',
                                          'verified', 'rejected')),
  preferred_lang  TEXT DEFAULT 'en',
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Index for role lookups
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);

-- Security Helper Functions (SECURITY DEFINER to avoid recursion)
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT COALESCE(
    (SELECT role IN ('super_admin', 'operations_admin', 'kyc_admin',
                     'finance_admin', 'warehouse_admin')
     FROM public.profiles WHERE id = auth.uid()),
    false
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS BOOLEAN AS $$
  SELECT COALESCE(
    (SELECT role = 'super_admin' FROM public.profiles WHERE id = auth.uid()),
    false
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Profiles RLS Policies:
-- 1. Users can select their own profile or any admin can select
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (id = auth.uid() OR is_admin());

-- 2. Users can update their own profile EXCEPT role, status, kyc_status
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT role FROM profiles WHERE id = auth.uid())
    AND status = (SELECT status FROM profiles WHERE id = auth.uid())
    AND kyc_status = (SELECT kyc_status FROM profiles WHERE id = auth.uid())
  );

-- Trigger to auto-create profile when a user registers
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, status, kyc_status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    'merchant',
    'active',
    'not_submitted'
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();
