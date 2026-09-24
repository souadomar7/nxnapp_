-- ============================================================
-- NXN App — Database Migration v4
-- Tracks: Inventory locking, warehouse shelves, payout ledgers,
--         Arabic FTS, Edge Function helpers
-- Run in Supabase SQL Editor after v3 migration.
-- ============================================================

-- ── 0. Extensions ─────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ── 1. warehouse_shelves — per-shelf granular occupancy ───
CREATE TABLE IF NOT EXISTS warehouse_shelves (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id  TEXT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  shelf_code    TEXT NOT NULL,       -- e.g. DXB-A-12-3
  zone          TEXT,                -- e.g. A, B, C
  aisle         TEXT,                -- e.g. 12
  tier          TEXT,                -- e.g. 3 (shelf level)
  status        TEXT NOT NULL DEFAULT 'available'
                  CHECK (status IN ('available','reserved_temp','occupied','maintenance')),
  merchant_id   UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reserved_until TIMESTAMP WITH TIME ZONE,   -- for temp holds
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL,
  UNIQUE (warehouse_id, shelf_code)
);

ALTER TABLE warehouse_shelves ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read warehouse shelves"
  ON warehouse_shelves FOR SELECT USING (true);
CREATE POLICY "Admin can manage shelves"
  ON warehouse_shelves FOR ALL USING (auth.role() = 'service_role');

-- ── 2. Extend sme_inventory for available/reserved tracking ─
ALTER TABLE sme_inventory ADD COLUMN IF NOT EXISTS available_quantity INTEGER NOT NULL DEFAULT 0;
ALTER TABLE sme_inventory ADD COLUMN IF NOT EXISTS reserved_quantity  INTEGER NOT NULL DEFAULT 0;
ALTER TABLE sme_inventory ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now());
ALTER TABLE sme_inventory ADD COLUMN IF NOT EXISTS shelf_id UUID REFERENCES warehouse_shelves(id) ON DELETE SET NULL;

-- ── 3. Extend sme_sellers with account_status ─────────────
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS account_status TEXT NOT NULL DEFAULT 'active'
  CHECK (account_status IN ('active', 'pending_license_verification', 'suspended'));

-- ── 4. payout_ledgers — merchant settlement records ───────
CREATE TABLE IF NOT EXISTS payout_ledgers (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  period_start        TIMESTAMP WITH TIME ZONE NOT NULL,
  period_end          TIMESTAMP WITH TIME ZONE NOT NULL,
  gross_sales         NUMERIC(12,2) NOT NULL DEFAULT 0,
  platform_commission NUMERIC(12,2) NOT NULL DEFAULT 0,  -- 5%
  storage_fees        NUMERIC(12,2) NOT NULL DEFAULT 0,
  vat_amount          NUMERIC(12,2) NOT NULL DEFAULT 0,  -- 5% of commission+fees
  net_payout          NUMERIC(12,2) NOT NULL DEFAULT 0,
  status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','processing','paid','failed','disputed')),
  bank_reference      TEXT,
  wps_batch_id        TEXT,
  paid_at             TIMESTAMP WITH TIME ZONE,
  notes               TEXT,
  created_at          TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

ALTER TABLE payout_ledgers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Sellers view own payout ledger"
  ON payout_ledgers FOR SELECT USING (auth.uid() = seller_id);
CREATE POLICY "Service role manages payouts"
  ON payout_ledgers FOR ALL USING (auth.role() = 'service_role');

-- ── 5. buyer_orders — add GPS + PoD fields ────────────────
ALTER TABLE buyer_orders ADD COLUMN IF NOT EXISTS delivery_lat       NUMERIC;
ALTER TABLE buyer_orders ADD COLUMN IF NOT EXISTS delivery_lng       NUMERIC;
ALTER TABLE buyer_orders ADD COLUMN IF NOT EXISTS delivery_address_text TEXT;
ALTER TABLE buyer_orders ADD COLUMN IF NOT EXISTS pod_photo_url      TEXT;
ALTER TABLE buyer_orders ADD COLUMN IF NOT EXISTS pod_timestamp      TIMESTAMP WITH TIME ZONE;
ALTER TABLE buyer_orders ADD COLUMN IF NOT EXISTS driver_id          UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE buyer_orders ADD COLUMN IF NOT EXISTS updated_at         TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now());

-- ── 6. Atomic Marketplace Checkout RPC ────────────────────
CREATE OR REPLACE FUNCTION process_marketplace_checkout(
  p_buyer_name    TEXT,
  p_buyer_phone   TEXT,
  p_buyer_email   TEXT,
  p_buyer_address TEXT,
  p_product_id    UUID,
  p_quantity      INT,
  p_unit_price    NUMERIC,
  p_emirate       TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_seller_id   UUID;
  v_inv_id      UUID;
  v_available   INT;
  v_order_id    UUID;
BEGIN
  -- Resolve seller from product
  SELECT seller_id INTO v_seller_id FROM sme_products WHERE id = p_product_id;
  IF v_seller_id IS NULL THEN
    RAISE EXCEPTION 'PRODUCT_NOT_FOUND';
  END IF;

  -- Lock inventory row to prevent race conditions
  SELECT id, available_quantity INTO v_inv_id, v_available
  FROM sme_inventory
  WHERE product_id = p_product_id
  FOR UPDATE;

  -- Fall back to product.quantity if no inventory row
  IF v_inv_id IS NULL THEN
    SELECT id, quantity INTO v_inv_id, v_available
    FROM sme_products WHERE id = p_product_id
    FOR UPDATE;
    IF v_available < p_quantity THEN
      RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available', v_available;
    END IF;
    UPDATE sme_products
    SET quantity = quantity - p_quantity
    WHERE id = p_product_id;
  ELSE
    IF v_available < p_quantity THEN
      RAISE EXCEPTION 'INSUFFICIENT_STOCK: Only % units available', v_available;
    END IF;
    UPDATE sme_inventory
    SET available_quantity = available_quantity - p_quantity,
        reserved_quantity  = reserved_quantity  + p_quantity,
        updated_at         = NOW()
    WHERE id = v_inv_id;
  END IF;

  -- Create confirmed buyer order
  INSERT INTO buyer_orders (
    buyer_name, buyer_phone, buyer_email, buyer_address,
    product_id, seller_id, quantity, unit_price,
    total_amount, emirate, payment_status, order_status
  ) VALUES (
    p_buyer_name, p_buyer_phone, p_buyer_email, p_buyer_address,
    p_product_id, v_seller_id, p_quantity, p_unit_price,
    (p_quantity * p_unit_price), p_emirate, 'paid', 'confirmed'
  ) RETURNING id INTO v_order_id;

  RETURN v_order_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 7. Arabic Full-Text Search on sme_products ────────────
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;

-- Populate existing rows
UPDATE sme_products
SET search_vector = to_tsvector('simple',
    COALESCE(name,'') || ' ' || COALESCE(name_ar,'') || ' ' || COALESCE(description,'')
);

-- Auto-update trigger
CREATE OR REPLACE FUNCTION update_product_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := to_tsvector('simple',
    COALESCE(NEW.name,'') || ' ' || COALESCE(NEW.name_ar,'') || ' ' || COALESCE(NEW.description,'')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tsvector_update_sme_products ON sme_products;
CREATE TRIGGER tsvector_update_sme_products
  BEFORE INSERT OR UPDATE ON sme_products
  FOR EACH ROW EXECUTE FUNCTION update_product_search_vector();

-- GIN index for fast FTS
CREATE INDEX IF NOT EXISTS idx_sme_products_search ON sme_products USING GIN(search_vector);
-- Trigram index for fuzzy matching
CREATE INDEX IF NOT EXISTS idx_sme_products_name_trgm    ON sme_products USING GIN(name    gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_sme_products_name_ar_trgm ON sme_products USING GIN(name_ar gin_trgm_ops);

-- ── 8. Stale shelf reservation cleaner (runs every 5 min) ─
-- Requires pg_cron enabled in Supabase (Dashboard → Extensions → pg_cron)
SELECT cron.schedule(
  'release-stale-shelf-locks',
  '*/5 * * * *',
  $$
    UPDATE warehouse_shelves
    SET status = 'available', merchant_id = NULL, reserved_until = NULL
    WHERE status = 'reserved_temp'
      AND reserved_until < NOW();
  $$
) ON CONFLICT DO NOTHING;

-- ── 9. Driver role support — extend sme_sellers ───────────
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'merchant'
  CHECK (role IN ('merchant','operator','driver','admin'));

-- ── 10. Delivery proofs storage bucket (run manually) ─────
-- In Supabase Dashboard → Storage → New Bucket → "delivery_proofs" (public: false)
-- Or via API:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('delivery_proofs', 'delivery_proofs', false);

-- ══ DONE v4 ══════════════════════════════════════════════
