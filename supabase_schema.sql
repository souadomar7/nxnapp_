-- ==============================================================================
-- NXN WAREHOUSES: CANONICAL SUPABASE SCHEMA (v3 — full requirements update)
--
-- New in v3 (run ALTER TABLE sections on existing DB, or run full script on new):
--   - sme_sellers: +email, +license_owner_name, +license_name,
--                  +selected_warehouse_id, +uae_pass_uuid, +terms_accepted_at
--   - sme_products: +name_ar, +is_hidden, +hidden_reason, +quantity
--   - sme_inventory: status now includes 'low_stock' and 'quarantine'
--   - sme_inbound_requests: +shipment_type (drop_off/pick_up), +pickup fields
--   - sme_orders: +product_id, +customer_phone, +customer_email, +quantity,
--                 +notes, expanded status values
--   - marketplace_shops: +is_approved, +is_featured, +featured_until,
--                        +license_document_url, +shop_description
--   - warehouses: additional entries (multiple per emirate)
--   - notifications: NEW table (in-app notification center)
--   - buyer_orders: NEW table (marketplace buyer purchases)
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. WAREHOUSES (Multiple per emirate in v3)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS warehouses (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    name_ar         TEXT,
    emirate         TEXT,
    address         TEXT,
    location_lat    NUMERIC,
    location_lng    NUMERIC,
    total_shelves   INTEGER NOT NULL DEFAULT 100,
    price_per_shelf NUMERIC DEFAULT 100.0,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- Legacy single warehouses (backward compat)
INSERT INTO warehouses (id, name, name_ar, emirate, address, total_shelves, price_per_shelf) VALUES
  ('dxb', 'Dubai Central Warehouse',    'مستودع دبي المركزي',        'Dubai',     'Al Quoz, Dubai',             200, 100.0),
  ('auh', 'Abu Dhabi Central Warehouse','مستودع أبوظبي المركزي',     'Abu Dhabi', 'Mussafah, Abu Dhabi',        150, 100.0),
  ('shj', 'Sharjah Central Warehouse',  'مستودع الشارقة المركزي',    'Sharjah',   'Industrial Area, Sharjah',   100, 100.0),
  ('aln', 'Al Ain Central Warehouse',   'مستودع العين المركزي',      'Al Ain',    'Sanaiya, Al Ain',            100, 100.0)
ON CONFLICT (id) DO NOTHING;

-- Additional warehouses per emirate (v3)
INSERT INTO warehouses (id, name, name_ar, emirate, address, total_shelves, price_per_shelf) VALUES
  ('dxb-2', 'Dubai South Warehouse',          'مستودع دبي الجنوب',          'Dubai',     'Dubai South Logistics District',  150, 100.0),
  ('dxb-3', 'Jebel Ali Free Zone Warehouse',  'مستودع جبل علي',             'Dubai',     'Jebel Ali Free Zone, Dubai',      120, 110.0),
  ('auh-2', 'Khalifa Industrial Zone Warehouse','مستودع كيزاد',             'Abu Dhabi', 'KIZAD, Abu Dhabi',                100, 105.0),
  ('shj-2', 'Hamriyah Free Zone Warehouse',   'مستودع منطقة حمرية الحرة',   'Sharjah',   'Hamriyah Free Zone, Sharjah',      80, 105.0),
  ('aln-2', 'Al Ain South Warehouse',          'مستودع العين الجنوبي',       'Al Ain',    'Al Jimi, Al Ain',                  60, 95.0)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- 2. SELLER PROFILES (extends auth.users) — v3: new columns
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_sellers (
    id                      UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    business_name           TEXT,
    contact_number          TEXT,
    license_number          TEXT,
    license_owner_name      TEXT,
    license_name            TEXT,
    email                   TEXT,
    uae_pass_uuid           TEXT,
    selected_warehouse_id   TEXT REFERENCES warehouses(id) ON DELETE SET NULL,
    terms_accepted_at       TIMESTAMP WITH TIME ZONE,
    is_verified             BOOLEAN DEFAULT false NOT NULL,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- Migration (safe — ADD COLUMN IF NOT EXISTS)
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS license_owner_name TEXT;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS license_name TEXT;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS uae_pass_uuid TEXT;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS selected_warehouse_id TEXT REFERENCES warehouses(id) ON DELETE SET NULL;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMP WITH TIME ZONE;

-- ==============================================================================
-- 3. PRODUCT CATALOGUE — v3: +name_ar, +quantity, +is_hidden, +hidden_reason
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_products (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id   UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name        TEXT NOT NULL,
    name_ar     TEXT,
    description TEXT,
    price       NUMERIC(10,2) NOT NULL,
    photo_url   TEXT,
    quantity    INTEGER NOT NULL DEFAULT 0,
    is_hidden   BOOLEAN DEFAULT false NOT NULL,
    hidden_reason TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- Migration
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS quantity INTEGER NOT NULL DEFAULT 0;
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS hidden_reason TEXT;

-- ==============================================================================
-- 4. PHYSICAL SHELF INVENTORY — v3: status includes low_stock + quarantine
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_inventory (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    product_id      UUID REFERENCES sme_products(id) ON DELETE SET NULL,
    warehouse_id    TEXT REFERENCES warehouses(id) ON DELETE SET NULL,
    shelf_label     TEXT,
    quantity        INTEGER NOT NULL DEFAULT 0,
    status          TEXT NOT NULL CHECK (status IN ('in_stock', 'low_stock', 'damaged', 'out_of_stock', 'reserved', 'quarantine')),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 5. INBOUND REQUESTS — v3: +shipment_type + pickup fields
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_inbound_requests (
    id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id                       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    warehouse_id                    TEXT REFERENCES warehouses(id) ON DELETE SET NULL,
    shipment_type                   TEXT NOT NULL DEFAULT 'drop_off'
                                        CHECK (shipment_type IN ('drop_off', 'pick_up')),
    expected_date                   TIMESTAMP WITH TIME ZONE,
    item_count                      INTEGER,
    gate_pass_code                  TEXT,
    labor_count                     INTEGER DEFAULT 0 NOT NULL,
    visual_inspection_requested     BOOLEAN DEFAULT false NOT NULL,
    pickup_location_name            TEXT,
    pickup_address                  TEXT,
    goods_type                      TEXT,
    pickup_contact_name             TEXT,
    pickup_contact_phone            TEXT,
    status                          TEXT NOT NULL DEFAULT 'pending'
                                        CHECK (status IN ('pending', 'accepted', 'received', 'completed', 'rejected')),
    notes                           TEXT,
    created_at                      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- Migration
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS shipment_type TEXT NOT NULL DEFAULT 'drop_off';
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS pickup_location_name TEXT;
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS pickup_address TEXT;
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS goods_type TEXT;
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS pickup_contact_name TEXT;
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS pickup_contact_phone TEXT;

-- ==============================================================================
-- 6. SUBSCRIPTIONS (Shelf Rental Periods)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_subscriptions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    warehouse_id    TEXT REFERENCES warehouses(id) ON DELETE CASCADE NOT NULL,
    shelves_count   INTEGER NOT NULL DEFAULT 1,
    start_date      TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date        TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active       BOOLEAN DEFAULT true NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 7. INVOICES (Billing Records)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_invoices (
    id                  TEXT PRIMARY KEY,
    seller_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    invoice_number      TEXT NOT NULL,
    warehouse_name      TEXT NOT NULL,
    amount              NUMERIC(10,2) NOT NULL,
    vat                 NUMERIC(10,2) NOT NULL DEFAULT 0,
    worker_fee          NUMERIC(10,2) NOT NULL DEFAULT 0,
    paid                BOOLEAN DEFAULT false NOT NULL,
    type                TEXT NOT NULL DEFAULT 'generic'
                            CHECK (type IN ('rental', 'delivery', 'generic')),
    metadata            JSONB,
    stripe_payment_id   TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 8. OUTBOUND ORDERS — v3: +product_id, +customer_phone, +customer_email,
--    +quantity, +notes, expanded status values
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    product_id          UUID REFERENCES sme_products(id) ON DELETE SET NULL,
    customer_name       TEXT,
    customer_phone      TEXT,
    customer_email      TEXT,
    customer_address    TEXT,
    delivery_method     TEXT CHECK (delivery_method IN ('pickup', 'standard', 'express', 'same_day')),
    status              TEXT NOT NULL DEFAULT 'pending'
                            CHECK (status IN (
                                'pending', 'confirmed', 'preparing',
                                'ready_for_shipment', 'shipped',
                                'picked', 'out_for_delivery',
                                'delivered', 'completed', 'cancelled'
                            )),
    total_amount        NUMERIC(10,2) DEFAULT 0.0 NOT NULL,
    quantity            INTEGER DEFAULT 1 NOT NULL,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- Migration
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES sme_products(id) ON DELETE SET NULL;
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS customer_email TEXT;
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS quantity INTEGER DEFAULT 1 NOT NULL;
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS notes TEXT;

-- ==============================================================================
-- 9. MARKETPLACE SHOPS — v3: +is_approved, +is_featured, +featured_until,
--    +license_document_url, +shop_description
-- ==============================================================================
CREATE TABLE IF NOT EXISTS marketplace_shops (
    id                      TEXT PRIMARY KEY,
    seller_id               UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    shop_name               TEXT NOT NULL,
    license_name            TEXT NOT NULL,
    shop_description        TEXT,
    is_verified             BOOLEAN DEFAULT false NOT NULL,
    is_approved             BOOLEAN DEFAULT false NOT NULL,
    is_featured             BOOLEAN DEFAULT false NOT NULL,
    featured_until          TIMESTAMP WITH TIME ZONE,
    license_document_url    TEXT,
    created_at              TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- Migration
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS featured_until TIMESTAMP WITH TIME ZONE;
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS license_document_url TEXT;
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS shop_description TEXT;

-- ==============================================================================
-- 10. DASHBOARD ACTIVITY LOG
-- ==============================================================================
CREATE TABLE IF NOT EXISTS dashboard_activities (
    id          TEXT PRIMARY KEY,
    seller_id   UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title       TEXT NOT NULL,
    subtitle    TEXT NOT NULL,
    type        TEXT NOT NULL CHECK (type IN ('rental', 'delivery', 'inventory', 'invoice', 'inbound')),
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 11. NOTIFICATIONS (NEW — in-app notification center)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title       TEXT NOT NULL,
    body        TEXT NOT NULL,
    type        TEXT NOT NULL DEFAULT 'general'
                    CHECK (type IN (
                        'general', 'order_placed', 'order_confirmed',
                        'order_preparing', 'ready_for_shipment', 'shipped',
                        'delivered', 'inbound_received', 'payment', 'system'
                    )),
    is_read     BOOLEAN DEFAULT false NOT NULL,
    metadata    JSONB,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 12. BUYER ORDERS (NEW — marketplace purchases separate from sme_orders)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS buyer_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_name      TEXT NOT NULL,
    buyer_phone     TEXT NOT NULL,
    buyer_email     TEXT,
    buyer_address   TEXT NOT NULL,
    product_id      UUID REFERENCES sme_products(id) ON DELETE SET NULL,
    seller_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    quantity        INTEGER NOT NULL DEFAULT 1,
    unit_price      NUMERIC(10,2) NOT NULL,
    total_amount    NUMERIC(10,2) NOT NULL,
    emirate         TEXT,
    payment_status  TEXT NOT NULL DEFAULT 'pending'
                        CHECK (payment_status IN ('pending', 'paid', 'refunded', 'failed')),
    order_status    TEXT NOT NULL DEFAULT 'pending'
                        CHECK (order_status IN (
                            'pending', 'confirmed', 'preparing',
                            'ready_for_shipment', 'shipped',
                            'delivered', 'cancelled'
                        )),
    notes           TEXT,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ==============================================================================

ALTER TABLE sme_sellers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_products             ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_inventory            ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_inbound_requests     ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_subscriptions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_invoices             ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_orders               ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_shops        ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_activities     ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications            ENABLE ROW LEVEL SECURITY;
ALTER TABLE buyer_orders             ENABLE ROW LEVEL SECURITY;

ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to warehouses"
  ON warehouses FOR SELECT USING (true);

CREATE POLICY "Sellers can manage their own profile"
  ON sme_sellers FOR ALL USING (auth.uid() = id);

CREATE POLICY "Public can browse products"
  ON sme_products FOR SELECT USING (true);
CREATE POLICY "Sellers manage their own products"
  ON sme_products FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Sellers manage their own inventory"
  ON sme_inventory FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Sellers manage their own inbound requests"
  ON sme_inbound_requests FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Sellers manage their own subscriptions"
  ON sme_subscriptions FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Sellers manage their own invoices"
  ON sme_invoices FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Sellers manage their own orders"
  ON sme_orders FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Public can browse verified shops"
  ON marketplace_shops FOR SELECT USING (true);
CREATE POLICY "Sellers manage their own shop"
  ON marketplace_shops FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Sellers view their own activity"
  ON dashboard_activities FOR ALL USING (auth.uid() = seller_id);

-- Notifications: each user sees only their own
CREATE POLICY "Users see their own notifications"
  ON notifications FOR ALL USING (auth.uid() = user_id);

-- Buyer orders: seller sees orders for their products; anyone can insert
CREATE POLICY "Sellers see buyer orders for their products"
  ON buyer_orders FOR SELECT USING (auth.uid() = seller_id);
CREATE POLICY "Anyone can place a buyer order"
  ON buyer_orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Sellers can update buyer order status"
  ON buyer_orders FOR UPDATE USING (auth.uid() = seller_id);

-- ==============================================================================
-- AUTO-CREATE SELLER PROFILE ON SIGNUP
-- ==============================================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  BEGIN
    INSERT INTO public.sme_sellers (id, business_name, email, is_verified)
    VALUES (
      new.id,
      COALESCE(new.raw_user_meta_data->>'full_name', 'New Merchant'),
      COALESCE(new.email, ''),
      false
    )
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- ENABLE REALTIME FOR NOTIFICATIONS AND BUYER ORDERS
-- (Run in Supabase Dashboard → Database → Replication, or via SQL below)
-- ==============================================================================
-- ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
-- ALTER PUBLICATION supabase_realtime ADD TABLE buyer_orders;
