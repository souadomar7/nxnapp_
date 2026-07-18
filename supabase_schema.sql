-- ==============================================================================
-- NXN WAREHOUSES: CANONICAL SUPABASE SCHEMA (v2 — consolidated)
-- 
-- Run this ONCE in the Supabase SQL Editor to set up the complete database.
-- If your database already exists, check each table first before running
-- to avoid "already exists" errors.
--
-- Tables:
--   1. warehouses              (static — pre-populated)
--   2. sme_sellers             (user profiles, extends auth.users)
--   3. sme_products            (product catalogue)
--   4. sme_inventory           (physical stock on shelves)
--   5. sme_inbound_requests    (gate passes / drop-offs)
--   6. sme_subscriptions       (shelf rental periods)
--   7. sme_invoices            (billing records)
--   8. sme_orders              (outbound delivery orders)
--   9. marketplace_shops       (verified public shop profiles)
--  10. dashboard_activities    (activity log)
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. WAREHOUSES (Static lookup table — not per-user)
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

INSERT INTO warehouses (id, name, name_ar, emirate, address, total_shelves, price_per_shelf) VALUES
  ('dxb', 'Dubai Central Warehouse',    'مستودع دبي المركزي',        'Dubai',       'Al Quoz, Dubai',             200, 100.0),
  ('auh', 'Abu Dhabi Central Warehouse','مستودع أبوظبي المركزي',     'Abu Dhabi',   'Mussafah, Abu Dhabi',        150, 100.0),
  ('shj', 'Sharjah Central Warehouse',  'مستودع الشارقة المركزي',    'Sharjah',     'Industrial Area, Sharjah',   100, 100.0),
  ('aln', 'Al Ain Central Warehouse',   'مستودع العين المركزي',      'Al Ain',      'Sanaiya, Al Ain',            100, 100.0)
ON CONFLICT (id) DO NOTHING;

-- ==============================================================================
-- 2. SELLER PROFILES (extends auth.users)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_sellers (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    business_name   TEXT,
    contact_number  TEXT,
    license_number  TEXT,
    is_verified     BOOLEAN DEFAULT false NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 3. PRODUCT CATALOGUE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_products (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id   UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name        TEXT NOT NULL,
    description TEXT,
    price       NUMERIC(10,2) NOT NULL,
    photo_url   TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 4. PHYSICAL SHELF INVENTORY
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_inventory (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    product_id      UUID REFERENCES sme_products(id) ON DELETE SET NULL,
    warehouse_id    TEXT REFERENCES warehouses(id) ON DELETE SET NULL,
    shelf_label     TEXT,           -- e.g. "Dubai-Shelf-04"
    quantity        INTEGER NOT NULL DEFAULT 0,
    status          TEXT NOT NULL CHECK (status IN ('in_stock', 'damaged', 'out_of_stock', 'reserved')),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 5. INBOUND REQUESTS (Gate Pass / Drop-Off)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_inbound_requests (
    id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id                       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    warehouse_id                    TEXT REFERENCES warehouses(id) ON DELETE SET NULL,
    expected_date                   TIMESTAMP WITH TIME ZONE,
    item_count                      INTEGER,
    gate_pass_code                  TEXT,
    labor_count                     INTEGER DEFAULT 0 NOT NULL,
    visual_inspection_requested     BOOLEAN DEFAULT false NOT NULL,
    status                          TEXT NOT NULL DEFAULT 'pending'
                                        CHECK (status IN ('pending', 'accepted', 'received', 'completed', 'rejected')),
    notes                           TEXT,
    created_at                      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

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
    stripe_payment_id   TEXT,       -- Stripe PaymentIntent ID (set after payment)
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 8. OUTBOUND ORDERS (Delivery Requests)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS sme_orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id           UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    customer_name       TEXT,
    customer_address    TEXT,
    delivery_method     TEXT CHECK (delivery_method IN ('pickup', 'standard', 'express', 'same_day')),
    status              TEXT NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'picked', 'out_for_delivery', 'delivered', 'completed', 'cancelled')),
    total_amount        NUMERIC(10,2) DEFAULT 0.0 NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- ==============================================================================
-- 9. MARKETPLACE SHOPS (Public Verified Shops)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS marketplace_shops (
    id              TEXT PRIMARY KEY,
    seller_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    shop_name       TEXT NOT NULL,
    license_name    TEXT NOT NULL,
    is_verified     BOOLEAN DEFAULT false NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

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
-- ROW LEVEL SECURITY (RLS)
-- ==============================================================================

-- Enable RLS on all user-specific tables
ALTER TABLE sme_sellers              ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_products             ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_inventory            ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_inbound_requests     ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_subscriptions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_invoices             ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_orders               ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_shops        ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_activities     ENABLE ROW LEVEL SECURITY;

-- Note: warehouses has NO RLS — it is a public read-only lookup table.
-- Add a restrictive policy if you want to prevent public writes:
ALTER TABLE warehouses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access to warehouses"
  ON warehouses FOR SELECT USING (true);

-- Seller profiles
CREATE POLICY "Sellers can manage their own profile"
  ON sme_sellers FOR ALL USING (auth.uid() = id);

-- Products: public read, private write
CREATE POLICY "Public can browse products"
  ON sme_products FOR SELECT USING (true);
CREATE POLICY "Sellers manage their own products"
  ON sme_products FOR ALL USING (auth.uid() = seller_id);

-- Inventory
CREATE POLICY "Sellers manage their own inventory"
  ON sme_inventory FOR ALL USING (auth.uid() = seller_id);

-- Inbound requests
CREATE POLICY "Sellers manage their own inbound requests"
  ON sme_inbound_requests FOR ALL USING (auth.uid() = seller_id);

-- Subscriptions
CREATE POLICY "Sellers manage their own subscriptions"
  ON sme_subscriptions FOR ALL USING (auth.uid() = seller_id);

-- Invoices
CREATE POLICY "Sellers manage their own invoices"
  ON sme_invoices FOR ALL USING (auth.uid() = seller_id);

-- Orders
CREATE POLICY "Sellers manage their own orders"
  ON sme_orders FOR ALL USING (auth.uid() = seller_id);

-- Marketplace shops: public read
CREATE POLICY "Public can browse verified shops"
  ON marketplace_shops FOR SELECT USING (true);
CREATE POLICY "Sellers manage their own shop"
  ON marketplace_shops FOR ALL USING (auth.uid() = seller_id);

-- Dashboard activity log
CREATE POLICY "Sellers view their own activity"
  ON dashboard_activities FOR ALL USING (auth.uid() = seller_id);
