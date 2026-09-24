-- ==============================================================================
-- 011_SUBSCRIPTION_EXPIRY.SQL
-- Subscription lifecycle management, cancellation workflow, grace periods,
-- and post-expiry enforcement stages.
-- ==============================================================================

-- Upgrade sme_subscriptions
ALTER TABLE sme_subscriptions ADD COLUMN IF NOT EXISTS grace_end_date TIMESTAMPTZ;
ALTER TABLE sme_subscriptions ADD COLUMN IF NOT EXISTS auto_renew BOOLEAN DEFAULT false;
ALTER TABLE sme_subscriptions ADD COLUMN IF NOT EXISTS cancellation_pending BOOLEAN DEFAULT false;
ALTER TABLE sme_subscriptions ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;
ALTER TABLE sme_subscriptions ADD COLUMN IF NOT EXISTS refund_amount NUMERIC(10,2) DEFAULT 0.0;
ALTER TABLE sme_subscriptions ADD COLUMN IF NOT EXISTS effective_end_date TIMESTAMPTZ;

-- Post-expiry automated events table
CREATE TABLE IF NOT EXISTS subscription_expiry_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES sme_subscriptions(id) ON DELETE CASCADE,
  stage           TEXT NOT NULL
                    CHECK (stage IN ('grace_period', 'storage_penalty', 'restricted_access', 'escalation')),
  effective_at    TIMESTAMPTZ NOT NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_expiry_sub_id ON subscription_expiry_events(subscription_id);

ALTER TABLE subscription_expiry_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Sellers view own expiry events" ON subscription_expiry_events;
CREATE POLICY "Sellers view own expiry events"
  ON subscription_expiry_events FOR SELECT
  USING (
    subscription_id IN (
      SELECT id FROM sme_subscriptions WHERE seller_id = auth.uid()
    ) OR public.is_admin()
  );

DROP POLICY IF EXISTS "Block client writes to expiry events" ON subscription_expiry_events;
CREATE POLICY "Block client writes to expiry events"
  ON subscription_expiry_events FOR INSERT
  WITH CHECK (false);
