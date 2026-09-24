-- ==============================================================================
-- 004_WALLET_LEDGER.SQL
-- Double-entry auditable wallet ledger.
-- Client CANNOT directly mutate balance; ledger entries drive or verify state.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS wallets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  currency    TEXT NOT NULL DEFAULT 'AED',
  balance_aed NUMERIC(12,2) NOT NULL DEFAULT 0.0 CHECK (balance_aed >= 0),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);

CREATE TABLE IF NOT EXISTS wallet_transactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id        UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
  type             TEXT NOT NULL
                     CHECK (type IN ('top_up', 'purchase', 'refund', 'withdrawal',
                                     'adjustment', 'payout', 'fee')),
  amount_aed       NUMERIC(12,2) NOT NULL CHECK (amount_aed > 0),
  direction        TEXT NOT NULL CHECK (direction IN ('credit', 'debit')),
  reference_type   TEXT, -- 'payment', 'order', 'booking', 'manual_adjustment'
  reference_id     UUID,
  status           TEXT NOT NULL DEFAULT 'completed'
                     CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  idempotency_key  TEXT UNIQUE,
  notes            TEXT,
  created_by       UUID REFERENCES auth.users(id),
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wallet_tx_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_created_at ON wallet_transactions(created_at DESC);

-- Enable RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

-- 1. Wallets RLS
DROP POLICY IF EXISTS "Users can read own wallet" ON wallets;
CREATE POLICY "Users can read own wallet"
  ON wallets FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

-- Strictly block client mutations:
DROP POLICY IF EXISTS "Block client insert into wallets" ON wallets;
CREATE POLICY "Block client insert into wallets"
  ON wallets FOR INSERT
  WITH CHECK (false);

DROP POLICY IF EXISTS "Block client update into wallets" ON wallets;
CREATE POLICY "Block client update into wallets"
  ON wallets FOR UPDATE
  USING (false);

-- 2. Wallet Transactions RLS
DROP POLICY IF EXISTS "Users can read own wallet transactions" ON wallet_transactions;
CREATE POLICY "Users can read own wallet transactions"
  ON wallet_transactions FOR SELECT
  USING (
    wallet_id IN (SELECT id FROM wallets WHERE user_id = auth.uid())
    OR public.is_admin()
  );

-- Strictly block client writes into transactions:
DROP POLICY IF EXISTS "Block client insert into wallet_transactions" ON wallet_transactions;
CREATE POLICY "Block client insert into wallet_transactions"
  ON wallet_transactions FOR INSERT
  WITH CHECK (false);

DROP POLICY IF EXISTS "Block client update into wallet_transactions" ON wallet_transactions;
CREATE POLICY "Block client update into wallet_transactions"
  ON wallet_transactions FOR UPDATE
  USING (false);
