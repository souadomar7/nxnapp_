-- ==============================================================================
-- 012_WAREHOUSE_HIERARCHY.SQL
-- Detailed physical storage topology: Warehouse -> Zone -> Rack -> Shelf.
-- Enables granular temperature zoning, QR-guided putaway, and capacity tracking.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS warehouse_zones (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  warehouse_id TEXT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  name         TEXT NOT NULL, -- e.g. "Zone A - Ambient"
  temp_type    TEXT NOT NULL CHECK (temp_type IN ('ambient', 'chilled', 'cold_storage')),
  is_active    BOOLEAN NOT NULL DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_zones_warehouse ON warehouse_zones(warehouse_id);

CREATE TABLE IF NOT EXISTS racks (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id      UUID NOT NULL REFERENCES warehouse_zones(id) ON DELETE CASCADE,
  warehouse_id TEXT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  name         TEXT NOT NULL, -- e.g. "Rack 01"
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_racks_zone ON racks(zone_id);

CREATE TABLE IF NOT EXISTS shelves (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rack_id           UUID NOT NULL REFERENCES racks(id) ON DELETE CASCADE,
  zone_id           UUID NOT NULL REFERENCES warehouse_zones(id) ON DELETE CASCADE,
  warehouse_id      TEXT NOT NULL REFERENCES warehouses(id) ON DELETE CASCADE,
  name              TEXT NOT NULL, -- e.g. "A-01-S1"
  temp_type         TEXT NOT NULL CHECK (temp_type IN ('ambient', 'chilled', 'cold_storage')),
  capacity_units    INTEGER NOT NULL DEFAULT 100,
  occupied_units    INTEGER NOT NULL DEFAULT 0,
  status            TEXT NOT NULL DEFAULT 'available'
                      CHECK (status IN ('available', 'reserved', 'occupied', 'maintenance', 'blocked')),
  qr_code           TEXT UNIQUE,
  monthly_price_aed NUMERIC(10,2) DEFAULT 100.0,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shelves_rack ON shelves(rack_id);
CREATE INDEX IF NOT EXISTS idx_shelves_warehouse_status ON shelves(warehouse_id, status);

-- Enable RLS
ALTER TABLE warehouse_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE racks ENABLE ROW LEVEL SECURITY;
ALTER TABLE shelves ENABLE ROW LEVEL SECURITY;

-- Read: Public can inspect warehouse structure
DROP POLICY IF EXISTS "Public read warehouse zones" ON warehouse_zones;
CREATE POLICY "Public read warehouse zones" ON warehouse_zones FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read racks" ON racks;
CREATE POLICY "Public read racks" ON racks FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public read shelves" ON shelves;
CREATE POLICY "Public read shelves" ON shelves FOR SELECT USING (true);

-- Modifications: Admins only
DROP POLICY IF EXISTS "Admins manage warehouse zones" ON warehouse_zones;
CREATE POLICY "Admins manage warehouse zones" ON warehouse_zones FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "Admins manage racks" ON racks;
CREATE POLICY "Admins manage racks" ON racks FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "Admins manage shelves" ON shelves;
CREATE POLICY "Admins manage shelves" ON shelves FOR ALL USING (public.is_admin());

-- Seed initial hierarchy for Dubai Central Warehouse ('dxb')
DO $$
DECLARE
  v_zone_amb UUID;
  v_zone_chi UUID;
  v_zone_cld UUID;
  v_rack_1   UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM warehouses WHERE id = 'dxb') THEN
    -- Insert Zone Ambient
    INSERT INTO warehouse_zones (warehouse_id, name, temp_type)
    VALUES ('dxb', 'Zone A (Ambient)', 'ambient')
    RETURNING id INTO v_zone_amb;

    -- Insert Zone Chilled
    INSERT INTO warehouse_zones (warehouse_id, name, temp_type)
    VALUES ('dxb', 'Zone B (Chilled)', 'chilled')
    RETURNING id INTO v_zone_chi;

    -- Insert Zone Cold Storage
    INSERT INTO warehouse_zones (warehouse_id, name, temp_type)
    VALUES ('dxb', 'Zone C (Cold Storage)', 'cold_storage')
    RETURNING id INTO v_zone_cld;

    -- Insert Rack in Ambient Zone
    INSERT INTO racks (zone_id, warehouse_id, name)
    VALUES (v_zone_amb, 'dxb', 'Rack 01')
    RETURNING id INTO v_rack_1;

    -- Insert Shelves on Rack 01
    INSERT INTO shelves (rack_id, zone_id, warehouse_id, name, temp_type, qr_code, monthly_price_aed)
    VALUES
      (v_rack_1, v_zone_amb, 'dxb', 'A-01-S1', 'ambient', 'NXN-DXB-A01S1', 100.0),
      (v_rack_1, v_zone_amb, 'dxb', 'A-01-S2', 'ambient', 'NXN-DXB-A01S2', 100.0),
      (v_rack_1, v_zone_amb, 'dxb', 'A-01-S3', 'ambient', 'NXN-DXB-A01S3', 100.0);
  END IF;
END $$;
