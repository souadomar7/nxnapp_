-- ==============================================================================
-- 006_INVENTORY_MOVEMENTS.SQL
-- Immutable audit log for physical stock flow: receive, putaway, move,
-- dispatch, return, adjustment, damage. Reconstructs shelf state accurately.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS inventory_movements (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id      UUID NOT NULL REFERENCES sme_products(id) ON DELETE CASCADE,
  seller_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  warehouse_id    TEXT REFERENCES warehouses(id) ON DELETE SET NULL,
  shelf_label     TEXT,
  movement_type   TEXT NOT NULL
                    CHECK (movement_type IN ('receive', 'putaway', 'move', 'reserve',
                                             'dispatch', 'return', 'adjustment', 'damage')),
  quantity_delta  INTEGER NOT NULL, -- positive for increase, negative for decrease
  reference_type  TEXT, -- 'inbound', 'order', 'adjustment', 'transfer'
  reference_id    UUID,
  notes           TEXT,
  created_by      UUID REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_movements_product ON inventory_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_movements_seller ON inventory_movements(seller_id);
CREATE INDEX IF NOT EXISTS idx_movements_created ON inventory_movements(created_at DESC);

-- Enable RLS
ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;

-- Read: Merchant can view movements of their own products; Admins can view all
DROP POLICY IF EXISTS "Users can view own inventory movements" ON inventory_movements;
CREATE POLICY "Users can view own inventory movements"
  ON inventory_movements FOR SELECT
  USING (seller_id = auth.uid() OR public.is_admin());

-- Insert: Allowed for owner or admin (service role handles authoritative movements)
DROP POLICY IF EXISTS "Users can create own inventory movements" ON inventory_movements;
CREATE POLICY "Users can create own inventory movements"
  ON inventory_movements FOR INSERT
  WITH CHECK (seller_id = auth.uid() OR public.is_admin());

-- Update & Delete: Strictly prohibited (immutable audit trail)
DROP POLICY IF EXISTS "Block update on inventory_movements" ON inventory_movements;
CREATE POLICY "Block update on inventory_movements"
  ON inventory_movements FOR UPDATE
  USING (false);

DROP POLICY IF EXISTS "Block delete on inventory_movements" ON inventory_movements;
CREATE POLICY "Block delete on inventory_movements"
  ON inventory_movements FOR DELETE
  USING (false);
