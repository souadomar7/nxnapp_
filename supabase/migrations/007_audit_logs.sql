-- ==============================================================================
-- 007_AUDIT_LOGS.SQL
-- Immutable system-wide audit trail for compliance, financial forensics,
-- KYC reviews, role promotions, and inventory discrepancies.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id     UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action       TEXT NOT NULL, -- e.g. 'role_change', 'kyc_review', 'seller_approval', 'refund'
  entity_type  TEXT NOT NULL, -- e.g. 'profiles', 'payments', 'kyc_submissions', 'shelves'
  entity_id    TEXT,
  old_value    JSONB,
  new_value    JSONB,
  ip_address   TEXT,
  user_agent   TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at DESC);

-- Enable RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Read: Accessible exclusively to administrative personnel
DROP POLICY IF EXISTS "Admins can view audit logs" ON audit_logs;
CREATE POLICY "Admins can view audit logs"
  ON audit_logs FOR SELECT
  USING (public.is_admin());

-- Writes: Blocked from direct client. Only service role/Edge Functions can insert.
DROP POLICY IF EXISTS "Block client insert into audit_logs" ON audit_logs;
CREATE POLICY "Block client insert into audit_logs"
  ON audit_logs FOR INSERT
  WITH CHECK (false);

DROP POLICY IF EXISTS "Block client update into audit_logs" ON audit_logs;
CREATE POLICY "Block client update into audit_logs"
  ON audit_logs FOR UPDATE
  USING (false);

DROP POLICY IF EXISTS "Block client delete into audit_logs" ON audit_logs;
CREATE POLICY "Block client delete into audit_logs"
  ON audit_logs FOR DELETE
  USING (false);
