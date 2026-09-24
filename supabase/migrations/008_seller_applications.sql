-- ==============================================================================
-- 008_SELLER_APPLICATIONS.SQL
-- Explicit onboarding state machine for merchants before store activation:
-- not_applied -> submitted -> under_review -> approved / rejected -> suspended.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS seller_applications (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shop_name        TEXT NOT NULL,
  trade_name       TEXT,
  license_number   TEXT,
  emirate          TEXT,
  status           TEXT NOT NULL DEFAULT 'submitted'
                     CHECK (status IN ('not_applied', 'submitted', 'under_review',
                                       'approved', 'rejected', 'suspended')),
  rejection_reason TEXT,
  reviewed_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at      TIMESTAMPTZ,
  submitted_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_seller_apps_user ON seller_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_seller_apps_status ON seller_applications(status);

-- Enable RLS
ALTER TABLE seller_applications ENABLE ROW LEVEL SECURITY;

-- Read: Merchant can view their own application; Admins can view all applications
DROP POLICY IF EXISTS "Users can view own application" ON seller_applications;
CREATE POLICY "Users can view own application"
  ON seller_applications FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

-- Submit: User can submit an application for themselves
DROP POLICY IF EXISTS "Users can submit application" ON seller_applications;
CREATE POLICY "Users can submit application"
  ON seller_applications FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Update: Only admins can transition statuses (approve, reject, suspend)
DROP POLICY IF EXISTS "Admins can update applications" ON seller_applications;
CREATE POLICY "Admins can update applications"
  ON seller_applications FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
