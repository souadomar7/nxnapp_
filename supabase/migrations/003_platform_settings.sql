-- ==============================================================================
-- 003_PLATFORM_SETTINGS.SQL
-- Dynamic platform parameters (VAT rate, platform fee, warehouse base rates).
-- Avoids hardcoded financial values in client code.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS platform_settings (
  key         TEXT PRIMARY KEY,
  value       TEXT NOT NULL,
  description TEXT,
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_by  UUID REFERENCES auth.users(id)
);

-- Seed default settings if not present
INSERT INTO platform_settings (key, value, description) VALUES
  ('vat_rate', '0.05', 'Standard UAE VAT rate (5%)'),
  ('platform_fee_rate', '0.05', 'Standard marketplace/rental platform fee (5%)'),
  ('shelf_base_price_aed', '100.0', 'Base monthly rental price per ambient shelf in AED'),
  ('worker_fee_per_unit_aed', '50.0', 'Per-worker monthly assistance fee in AED'),
  ('free_product_listing_limit', '5', 'Max free products before merchant must be featured/pay fee'),
  ('seller_payout_hold_days', '14', 'Number of days hold period before IBAN settlement clearance'),
  ('max_wallet_withdrawal_aed', '50000.0', 'Maximum single withdrawal amount from wallet in AED'),
  ('daily_withdrawal_limit_aed', '10000.0', 'Maximum daily withdrawal threshold in AED')
ON CONFLICT (key) DO NOTHING;

-- RLS
ALTER TABLE platform_settings ENABLE ROW LEVEL SECURITY;

-- Everyone authenticated can read settings
DROP POLICY IF EXISTS "Public authenticated read platform settings" ON platform_settings;
CREATE POLICY "Public authenticated read platform settings"
  ON platform_settings FOR SELECT
  USING (true);

-- Only super_admin can update settings
DROP POLICY IF EXISTS "Super admin can modify platform settings" ON platform_settings;
CREATE POLICY "Super admin can modify platform settings"
  ON platform_settings FOR ALL
  USING (public.is_super_admin())
  WITH CHECK (public.is_super_admin());
