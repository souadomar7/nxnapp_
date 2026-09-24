-- ==============================================================================
-- 005_PAYMENTS_TABLE.SQL
-- Centralized payments state machine table.
-- Driven by Stripe Webhooks and Edge Functions.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS payments (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payer_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reference_type           TEXT NOT NULL, -- 'booking', 'invoice', 'order', 'wallet_topup'
  reference_id             TEXT NOT NULL, -- UUID or string reference ID
  stripe_payment_intent_id TEXT UNIQUE,
  stripe_charge_id         TEXT,
  amount_aed               NUMERIC(12,2) NOT NULL,
  subtotal_aed             NUMERIC(12,2) NOT NULL,
  platform_fee_aed         NUMERIC(12,2) NOT NULL DEFAULT 0.0,
  vat_aed                  NUMERIC(12,2) NOT NULL DEFAULT 0.0,
  currency                 TEXT NOT NULL DEFAULT 'AED',
  status                   TEXT NOT NULL DEFAULT 'pending'
                             CHECK (status IN ('pending', 'processing', 'paid',
                                               'failed', 'cancelled', 'refunded',
                                               'partially_refunded')),
  refund_amount_aed        NUMERIC(12,2) DEFAULT 0.0,
  idempotency_key          TEXT UNIQUE,
  paid_at                  TIMESTAMPTZ,
  created_at               TIMESTAMPTZ DEFAULT NOW(),
  updated_at               TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_payer_id ON payments(payer_id);
CREATE INDEX IF NOT EXISTS idx_payments_stripe_pi ON payments(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

-- Enable RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Read: Payer can read their own payments; Admins can read all
DROP POLICY IF EXISTS "Users can read own payments" ON payments;
CREATE POLICY "Users can read own payments"
  ON payments FOR SELECT
  USING (payer_id = auth.uid() OR public.is_admin());

-- Writes: Block ALL client inserts and updates. Payments must come through backend.
DROP POLICY IF EXISTS "Block client insert into payments" ON payments;
CREATE POLICY "Block client insert into payments"
  ON payments FOR INSERT
  WITH CHECK (false);

DROP POLICY IF EXISTS "Block client update into payments" ON payments;
CREATE POLICY "Block client update into payments"
  ON payments FOR UPDATE
  USING (false);
