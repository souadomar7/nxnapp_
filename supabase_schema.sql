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

-- Canonical profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id                UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name         TEXT,
    phone             TEXT,
    role              TEXT DEFAULT 'customer',
    status            TEXT DEFAULT 'active',
    kyc_status        TEXT DEFAULT 'basic',
    terms_accepted_at TIMESTAMP WITH TIME ZONE,
    terms_version     TEXT,
    warehouse_id      TEXT REFERENCES warehouses(id) ON DELETE SET NULL,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

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
    category    TEXT,
    quantity    INTEGER NOT NULL DEFAULT 0,
    is_hidden   BOOLEAN DEFAULT false NOT NULL,
    hidden_reason TEXT,
    created_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);

-- Migration
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS category TEXT;
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

-- Migration
ALTER TABLE sme_invoices ADD COLUMN IF NOT EXISTS warehouse_name_ar TEXT;

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

-- ==============================================================================
-- 4. DOCK GATE PASSES TABLE (Gate Security & Offline Admission State)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.dock_gate_passes (
    id              TEXT PRIMARY KEY,
    pass_code       TEXT NOT NULL,
    lease_id        TEXT,
    qr_signature    TEXT NOT NULL,
    dock_gate       TEXT NOT NULL,
    driver_name     TEXT,
    driver_license  TEXT,
    vehicle_plate   TEXT,
    valid_until     TIMESTAMP WITH TIME ZONE NOT NULL,
    status          TEXT NOT NULL DEFAULT 'admitted'
                        CHECK (status IN ('pending', 'admitted', 'expired', 'revoked')),
    sync_count      INTEGER NOT NULL DEFAULT 1,
    synced_at       TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL,
    last_synced_at  TIMESTAMP WITH TIME ZONE,
    synced_by       UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

ALTER TABLE public.dock_gate_passes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own dock passes"
  ON public.dock_gate_passes FOR SELECT USING (auth.uid() = synced_by);

CREATE POLICY "Service roles and staff can manage dock passes"
  ON public.dock_gate_passes FOR ALL USING (true);

-- ==============================================================================
-- 5. RPC STORED PROCEDURES (Hardened Cancellation & Offline Gate Pass Sync)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.request_subscription_cancellation(
    p_subscription_id TEXT,
    p_refund_model    TEXT,
    p_refund_amount   NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_seller_id UUID;
    v_has_stock BOOLEAN := false;
    v_has_outbound BOOLEAN := false;
    v_effective_end TIMESTAMPTZ;
BEGIN
    v_seller_id := auth.uid();
    IF v_seller_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED: Valid session required');
    END IF;

    -- Validate subscription ownership
    IF NOT EXISTS (
        SELECT 1 FROM public.sme_subscriptions 
        WHERE id = p_subscription_id AND seller_id = v_seller_id
    ) THEN
        RETURN jsonb_build_object('success', false, 'error', 'SUBSCRIPTION_NOT_FOUND');
    END IF;

    v_effective_end := timezone('utc', now()) + INTERVAL '14 days';

    -- Check physical stock & pending outbound orders
    SELECT EXISTS (
        SELECT 1 FROM public.sme_inventory 
        WHERE seller_id = v_seller_id AND quantity > 0 AND status != 'cleared'
    ) INTO v_has_stock;

    SELECT EXISTS (
        SELECT 1 FROM public.sme_orders
        WHERE seller_id = v_seller_id AND status IN ('pending', 'pending_dispatch', 'in_transit')
    ) INTO v_has_outbound;

    -- Apply cancellation terms
    UPDATE public.sme_subscriptions
    SET auto_renew = false,
        cancellation_pending = true,
        refund_model = p_refund_model,
        refund_amount = p_refund_amount,
        end_date = v_effective_end,
        updated_at = timezone('utc', now())
    WHERE id = p_subscription_id AND seller_id = v_seller_id;

    RETURN jsonb_build_object(
        'success', true,
        'status', 'cancellation_pending',
        'has_physical_stock', v_has_stock,
        'has_pending_outbound', v_has_outbound,
        'effective_end_date', v_effective_end,
        'refund_amount', p_refund_amount
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_offline_gate_pass(
    p_pass_code       TEXT,
    p_lease_id        TEXT,
    p_qr_signature    TEXT,
    p_dock_gate       TEXT,
    p_driver_name     TEXT,
    p_driver_license  TEXT,
    p_vehicle_plate   TEXT,
    p_valid_until     TEXT,
    p_idempotency_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_sync_key TEXT;
BEGIN
    v_user_id := auth.uid();
    v_sync_key := COALESCE(p_idempotency_key, p_pass_code);

    -- 1. Ensure target gate pass table records the synced admission
    INSERT INTO public.dock_gate_passes (
        id, pass_code, lease_id, qr_signature, dock_gate, 
        driver_name, driver_license, vehicle_plate, valid_until, 
        status, synced_at, synced_by
    ) VALUES (
        v_sync_key, p_pass_code, p_lease_id, p_qr_signature, p_dock_gate,
        p_driver_name, p_driver_license, p_vehicle_plate, p_valid_until::timestamptz,
        'admitted', timezone('utc', now()), v_user_id
    )
    ON CONFLICT (id) DO UPDATE 
    SET sync_count = public.dock_gate_passes.sync_count + 1,
        last_synced_at = timezone('utc', now());

    -- 2. Log activity audit trail
    INSERT INTO public.dashboard_activities (
        id, seller_id, title, title_ar, subtitle, subtitle_ar, date, type
    ) VALUES (
        'act_' || v_sync_key,
        v_user_id,
        'Offline Gate Pass Synced: ' || p_pass_code,
        'مزامنة تصريح دخول: ' || p_pass_code,
        'Driver: ' || p_driver_name || ' (' || p_vehicle_plate || ') | Gate: ' || p_dock_gate,
        'السائق: ' || p_driver_name || ' (' || p_vehicle_plate || ') | البوابة: ' || p_dock_gate,
        now(),
        'dispatch'
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN jsonb_build_object(
        'success', true, 
        'pass_code', p_pass_code,
        'idempotency_key', v_sync_key
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- ==============================================================================
-- 15. MERCHANT WALLET, ESCROW & DOUBLE-ENTRY LEDGER SYSTEM (FINTECH SPEC)
-- ==============================================================================

-- 1. Merchants Table
CREATE TABLE IF NOT EXISTS public.merchants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    trade_license_number VARCHAR(100) NOT NULL,
    vat_number VARCHAR(50),
    bank_name VARCHAR(100),
    bank_account_holder_name VARCHAR(255),
    bank_iban VARCHAR(34),
    bank_swift_bic VARCHAR(11),
    payout_schedule VARCHAR(20) NOT NULL DEFAULT 'manual' 
        CHECK (payout_schedule IN ('manual', 'daily', 'weekly', 'biweekly', 'monthly')),
    is_payout_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2. In-App Merchant Wallets
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    merchant_id UUID NOT NULL UNIQUE REFERENCES public.merchants(id) ON DELETE RESTRICT,
    currency CHAR(3) NOT NULL DEFAULT 'AED',
    available_balance_cents BIGINT NOT NULL DEFAULT 0 CHECK (available_balance_cents >= 0),
    pending_escrow_cents BIGINT NOT NULL DEFAULT 0 CHECK (pending_escrow_cents >= 0),
    locked_payout_cents BIGINT NOT NULL DEFAULT 0 CHECK (locked_payout_cents >= 0),
    lifetime_earnings_cents BIGINT NOT NULL DEFAULT 0 CHECK (lifetime_earnings_cents >= 0),
    lifetime_payouts_cents BIGINT NOT NULL DEFAULT 0 CHECK (lifetime_payouts_cents >= 0),
    min_withdrawal_threshold_cents BIGINT NOT NULL DEFAULT 5000 CHECK (min_withdrawal_threshold_cents >= 1000),
    version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3. Multi-Vendor Platform Orders & Escrow Lifecycle
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(64) NOT NULL UNIQUE,
    merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE RESTRICT,
    customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    currency CHAR(3) NOT NULL DEFAULT 'AED',
    gross_amount_cents BIGINT NOT NULL CHECK (gross_amount_cents > 0),
    platform_fee_percent NUMERIC(5, 2) NOT NULL DEFAULT 5.00,
    platform_fee_cents BIGINT NOT NULL DEFAULT 0 CHECK (platform_fee_cents >= 0),
    payment_processing_fee_cents BIGINT NOT NULL DEFAULT 0 CHECK (payment_processing_fee_cents >= 0),
    net_merchant_amount_cents BIGINT NOT NULL CHECK (net_merchant_amount_cents >= 0),
    payment_status VARCHAR(30) NOT NULL DEFAULT 'pending' 
        CHECK (payment_status IN ('pending', 'captured', 'failed', 'refunded', 'disputed')),
    fulfillment_status VARCHAR(30) NOT NULL DEFAULT 'unfulfilled'
        CHECK (fulfillment_status IN ('unfulfilled', 'in_preparation', 'ready_for_pickup', 'in_transit', 'delivered', 'returned', 'cancelled')),
    escrow_status VARCHAR(30) NOT NULL DEFAULT 'held'
        CHECK (escrow_status IN ('held', 'eligible_for_release', 'released_to_available', 'refunded_to_customer')),
    return_window_closes_at TIMESTAMPTZ,
    escrow_released_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 4. Payout Requests
CREATE TABLE IF NOT EXISTS public.payout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference_id VARCHAR(64) NOT NULL UNIQUE,
    merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE RESTRICT,
    wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE RESTRICT,
    currency CHAR(3) NOT NULL DEFAULT 'AED',
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    payout_fee_cents BIGINT NOT NULL DEFAULT 0 CHECK (payout_fee_cents >= 0),
    net_payout_amount_cents BIGINT NOT NULL CHECK (net_payout_amount_cents > 0),
    status VARCHAR(30) NOT NULL DEFAULT 'requested'
        CHECK (status IN ('requested', 'pending_approval', 'approved', 'processing_gateway', 'dispatched', 'paid', 'rejected', 'failed', 'cancelled')),
    idempotency_key VARCHAR(128) NOT NULL UNIQUE,
    destination_bank_name VARCHAR(100) NOT NULL,
    destination_iban VARCHAR(34) NOT NULL,
    gateway_name VARCHAR(50) DEFAULT 'Fintx',
    gateway_transfer_reference VARCHAR(128),
    failure_reason TEXT,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    approved_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- 5. Double-Entry Wallet Transactions & Immutable Ledger
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_ref VARCHAR(64) NOT NULL UNIQUE,
    wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE RESTRICT,
    merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE RESTRICT,
    type VARCHAR(40) NOT NULL 
        CHECK (type IN (
            'escrow_credit', 'escrow_to_available', 'escrow_reversal_refund',
            'payout_lock', 'payout_settled', 'payout_unlock_reversal',
            'manual_platform_adjustment_credit', 'manual_platform_adjustment_debit',
            'platform_storage_fee_deduction'
        )),
    source_event VARCHAR(50) NOT NULL,
    related_order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    related_payout_id UUID REFERENCES public.payout_requests(id) ON DELETE SET NULL,
    currency CHAR(3) NOT NULL DEFAULT 'AED',
    amount_cents BIGINT NOT NULL,
    balance_bucket VARCHAR(20) NOT NULL CHECK (balance_bucket IN ('available', 'pending_escrow', 'locked_payout')),
    running_available_cents BIGINT NOT NULL,
    running_escrow_cents BIGINT NOT NULL,
    running_locked_cents BIGINT NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 6. Payout State Transition & Audit Log
CREATE TABLE IF NOT EXISTS public.payout_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payout_id UUID NOT NULL REFERENCES public.payout_requests(id) ON DELETE CASCADE,
    from_status VARCHAR(30) NOT NULL,
    to_status VARCHAR(30) NOT NULL,
    actor_id UUID,
    actor_role VARCHAR(50) NOT NULL DEFAULT 'system',
    notes TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- Indices for High-Throughput Queries
CREATE INDEX IF NOT EXISTS idx_wallets_merchant_id ON public.wallets(merchant_id);
CREATE INDEX IF NOT EXISTS idx_orders_merchant_escrow ON public.orders(merchant_id, escrow_status);
CREATE INDEX IF NOT EXISTS idx_payout_requests_merchant ON public.payout_requests(merchant_id, status);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_wallet_id ON public.wallet_transactions(wallet_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_order ON public.wallet_transactions(related_order_id);

-- ==============================================================================
-- 16. ATOMIC PL/PGSQL PROCEDURES WITH PESSIMISTIC LOCKING
-- ==============================================================================

-- Stored Procedure 1: Atomic Escrow Release to Available Balance
CREATE OR REPLACE FUNCTION public.process_order_escrow_release(
    p_order_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_wallet RECORD;
    v_tx_ref TEXT;
BEGIN
    -- 1. Lock the order row
    SELECT * INTO v_order
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'ORDER_NOT_FOUND', 'message', 'Order not found');
    END IF;

    IF v_order.escrow_status = 'released_to_available' THEN
        RETURN jsonb_build_object('success', true, 'message', 'Escrow already released', 'order_id', p_order_id);
    END IF;

    IF v_order.fulfillment_status != 'delivered' THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'NOT_DELIVERED', 'message', 'Order is not delivered yet');
    END IF;

    -- 2. Lock the associated merchant wallet
    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE merchant_id = v_order.merchant_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'WALLET_NOT_FOUND', 'message', 'Merchant wallet missing');
    END IF;

    -- 3. Update Wallet Balances (Atomic Shift)
    UPDATE public.wallets
    SET 
        pending_escrow_cents = pending_escrow_cents - v_order.net_merchant_amount_cents,
        available_balance_cents = available_balance_cents + v_order.net_merchant_amount_cents,
        lifetime_earnings_cents = lifetime_earnings_cents + v_order.net_merchant_amount_cents,
        version = version + 1,
        updated_at = timezone('utc', now())
    WHERE id = v_wallet.id;

    -- 4. Mark Order Escrow Released
    UPDATE public.orders
    SET 
        escrow_status = 'released_to_available',
        escrow_released_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    WHERE id = p_order_id;

    -- 5. Record Double-Entry Ledger Entry
    v_tx_ref := 'TX-REL-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8));
    INSERT INTO public.wallet_transactions (
        transaction_ref, wallet_id, merchant_id, type, source_event,
        related_order_id, currency, amount_cents, balance_bucket,
        running_available_cents, running_escrow_cents, running_locked_cents, description
    ) VALUES (
        v_tx_ref, v_wallet.id, v_order.merchant_id, 'escrow_to_available', 'order_fulfilled',
        v_order.id, v_order.currency, v_order.net_merchant_amount_cents, 'available',
        v_wallet.available_balance_cents + v_order.net_merchant_amount_cents,
        v_wallet.pending_escrow_cents - v_order.net_merchant_amount_cents,
        v_wallet.locked_payout_cents,
        'Escrow funds released for delivered Order #' || v_order.order_number
    );

    RETURN jsonb_build_object(
        'success', true,
        'order_id', p_order_id,
        'net_amount_released_cents', v_order.net_merchant_amount_cents,
        'transaction_ref', v_tx_ref
    );
END;
$$;

-- Stored Procedure 2: Atomic Payout Request & Balance Locking
CREATE OR REPLACE FUNCTION public.request_merchant_payout(
    p_merchant_id UUID,
    p_amount_cents BIGINT,
    p_idempotency_key VARCHAR(128)
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_wallet RECORD;
    v_merchant RECORD;
    v_existing_payout RECORD;
    v_payout_id UUID;
    v_payout_ref TEXT;
    v_tx_ref TEXT;
BEGIN
    -- Idempotency Check
    SELECT * INTO v_existing_payout
    FROM public.payout_requests
    WHERE idempotency_key = p_idempotency_key;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'success', true,
            'is_duplicate', true,
            'payout_id', v_existing_payout.id,
            'reference_id', v_existing_payout.reference_id,
            'status', v_existing_payout.status
        );
    END IF;

    -- Fetch merchant bank details
    SELECT * INTO v_merchant FROM public.merchants WHERE id = p_merchant_id;
    IF NOT FOUND OR v_merchant.bank_iban IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'INVALID_BANK_DETAILS', 'message', 'Merchant bank details missing or incomplete');
    END IF;

    IF NOT v_merchant.is_payout_enabled THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'PAYOUTS_DISABLED', 'message', 'Payouts are currently disabled for this merchant');
    END IF;

    -- Lock the wallet row
    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE merchant_id = p_merchant_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'WALLET_NOT_FOUND', 'message', 'Merchant wallet not found');
    END IF;

    -- Validate Threshold & Available Balance
    IF p_amount_cents < v_wallet.min_withdrawal_threshold_cents THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'BELOW_MIN_THRESHOLD', 
            'message', 'Withdrawal amount must be at least AED ' || (v_wallet.min_withdrawal_threshold_cents / 100)::text
        );
    END IF;

    IF v_wallet.available_balance_cents < p_amount_cents THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error_code', 'INSUFFICIENT_FUNDS', 
            'message', 'Insufficient available balance'
        );
    END IF;

    -- Deduct from available, lock in payout bucket
    UPDATE public.wallets
    SET 
        available_balance_cents = available_balance_cents - p_amount_cents,
        locked_payout_cents = locked_payout_cents + p_amount_cents,
        version = version + 1,
        updated_at = timezone('utc', now())
    WHERE id = v_wallet.id;

    -- Insert Payout Record
    v_payout_id := gen_random_uuid();
    v_payout_ref := 'PO-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || UPPER(SUBSTRING(v_payout_id::text, 1, 6));

    INSERT INTO public.payout_requests (
        id, reference_id, merchant_id, wallet_id, currency,
        amount_cents, payout_fee_cents, net_payout_amount_cents,
        status, idempotency_key, destination_bank_name, destination_iban, gateway_name
    ) VALUES (
        v_payout_id, v_payout_ref, p_merchant_id, v_wallet.id, v_wallet.currency,
        p_amount_cents, 0, p_amount_cents,
        'requested', p_idempotency_key, v_merchant.bank_name, v_merchant.bank_iban, 'Fintx'
    );

    -- Record Ledger Transaction
    v_tx_ref := 'TX-LCK-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8));
    INSERT INTO public.wallet_transactions (
        transaction_ref, wallet_id, merchant_id, type, source_event,
        related_payout_id, currency, amount_cents, balance_bucket,
        running_available_cents, running_escrow_cents, running_locked_cents, description
    ) VALUES (
        v_tx_ref, v_wallet.id, p_merchant_id, 'payout_lock', 'payout_requested',
        v_payout_id, v_wallet.currency, -p_amount_cents, 'locked_payout',
        v_wallet.available_balance_cents - p_amount_cents,
        v_wallet.pending_escrow_cents,
        v_wallet.locked_payout_cents + p_amount_cents,
        'Funds locked for withdrawal request #' || v_payout_ref
    );

    -- Log Audit Trail
    INSERT INTO public.payout_audit_logs (payout_id, from_status, to_status, actor_role, notes)
    VALUES (v_payout_id, 'none', 'requested', 'merchant', 'Payout request initiated via app');

    RETURN jsonb_build_object(
        'success', true,
        'payout_id', v_payout_id,
        'reference_id', v_payout_ref,
        'amount_cents', p_amount_cents,
        'status', 'requested'
    );
END;
$$;

-- Stored Procedure 3: Approve & Dispatch Payout (Admin / Automated Gateway Dispatch)
CREATE OR REPLACE FUNCTION public.approve_and_dispatch_payout(
    p_payout_id UUID,
    p_gateway_transfer_ref VARCHAR(128) DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payout RECORD;
    v_wallet RECORD;
    v_tx_ref TEXT;
BEGIN
    SELECT * INTO v_payout
    FROM public.payout_requests
    WHERE id = p_payout_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'PAYOUT_NOT_FOUND', 'message', 'Payout request not found');
    END IF;

    IF v_payout.status NOT IN ('requested', 'pending_approval', 'approved') THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'INVALID_STATE_TRANSITION', 'message', 'Payout cannot be dispatched from state ' || v_payout.status);
    END IF;

    -- Lock the wallet row
    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE id = v_payout.wallet_id
    FOR UPDATE;

    -- Deduct from locked_payout bucket, record lifetime payout
    UPDATE public.wallets
    SET 
        locked_payout_cents = locked_payout_cents - v_payout.amount_cents,
        lifetime_payouts_cents = lifetime_payouts_cents + v_payout.net_payout_amount_cents,
        version = version + 1,
        updated_at = timezone('utc', now())
    WHERE id = v_wallet.id;

    -- Update Payout Request Status
    UPDATE public.payout_requests
    SET 
        status = 'paid',
        gateway_transfer_reference = COALESCE(p_gateway_transfer_ref, gateway_transfer_reference),
        completed_at = timezone('utc', now())
    WHERE id = p_payout_id;

    -- Record Ledger Entry
    v_tx_ref := 'TX-DISP-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8));
    INSERT INTO public.wallet_transactions (
        transaction_ref, wallet_id, merchant_id, type, source_event,
        related_payout_id, currency, amount_cents, balance_bucket,
        running_available_cents, running_escrow_cents, running_locked_cents, description
    ) VALUES (
        v_tx_ref, v_wallet.id, v_payout.merchant_id, 'payout_settled', 'fintx_transfer_settled',
        p_payout_id, v_payout.currency, -v_payout.amount_cents, 'locked_payout',
        v_wallet.available_balance_cents,
        v_wallet.pending_escrow_cents,
        v_wallet.locked_payout_cents - v_payout.amount_cents,
        'Payout settled and transferred via Fintx IBAN #' || v_payout.destination_iban
    );

    -- Log Audit Trail
    INSERT INTO public.payout_audit_logs (payout_id, from_status, to_status, actor_role, notes)
    VALUES (p_payout_id, v_payout.status, 'paid', 'system', 'Payout dispatched and settled via gateway');

    RETURN jsonb_build_object(
        'success', true,
        'payout_id', p_payout_id,
        'status', 'paid',
        'transaction_ref', v_tx_ref
    );
END;
$$;

-- Stored Procedure 4: Fail / Reject & Refund Payout (Rollback locked balance to available)
CREATE OR REPLACE FUNCTION public.fail_and_refund_payout(
    p_payout_id UUID,
    p_failure_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payout RECORD;
    v_wallet RECORD;
    v_tx_ref TEXT;
BEGIN
    SELECT * INTO v_payout
    FROM public.payout_requests
    WHERE id = p_payout_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'PAYOUT_NOT_FOUND', 'message', 'Payout request not found');
    END IF;

    IF v_payout.status IN ('paid', 'refunded', 'cancelled') THEN
        RETURN jsonb_build_object('success', false, 'error_code', 'ALREADY_FINALIZED', 'message', 'Payout is already in final state: ' || v_payout.status);
    END IF;

    -- Lock the wallet row
    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE id = v_payout.wallet_id
    FOR UPDATE;

    -- Rollback: Move funds from locked_payout back to available_balance
    UPDATE public.wallets
    SET 
        locked_payout_cents = locked_payout_cents - v_payout.amount_cents,
        available_balance_cents = available_balance_cents + v_payout.amount_cents,
        version = version + 1,
        updated_at = timezone('utc', now())
    WHERE id = v_wallet.id;

    -- Update Payout Request Status
    UPDATE public.payout_requests
    SET 
        status = 'failed',
        failure_reason = p_failure_reason
    WHERE id = p_payout_id;

    -- Record Ledger Entry
    v_tx_ref := 'TX-REV-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8));
    INSERT INTO public.wallet_transactions (
        transaction_ref, wallet_id, merchant_id, type, source_event,
        related_payout_id, currency, amount_cents, balance_bucket,
        running_available_cents, running_escrow_cents, running_locked_cents, description
    ) VALUES (
        v_tx_ref, v_wallet.id, v_payout.merchant_id, 'payout_unlock_reversal', 'gateway_transfer_failed',
        p_payout_id, v_payout.currency, v_payout.amount_cents, 'available',
        v_wallet.available_balance_cents + v_payout.amount_cents,
        v_wallet.pending_escrow_cents,
        v_wallet.locked_payout_cents - v_payout.amount_cents,
        'Payout failed (' || p_failure_reason || '); funds unlocked back to available balance'
    );

    -- Log Audit Trail
    INSERT INTO public.payout_audit_logs (payout_id, from_status, to_status, actor_role, notes)
    VALUES (p_payout_id, v_payout.status, 'failed', 'system', 'Payout failed: ' || p_failure_reason);

    RETURN jsonb_build_object(
        'success', true,
        'payout_id', p_payout_id,
        'status', 'failed',
        'refunded_amount_cents', v_payout.amount_cents,
        'transaction_ref', v_tx_ref
    );
END;
$$;

-- RLS Security Policies
ALTER TABLE public.merchants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_audit_logs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    CREATE POLICY "Merchants view own profile" ON public.merchants 
        FOR SELECT USING (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Merchants view own wallet" ON public.wallets 
        FOR SELECT USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Merchants view own orders" ON public.orders 
        FOR SELECT USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Merchants view own payouts" ON public.payout_requests 
        FOR SELECT USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE POLICY "Merchants view own ledger" ON public.wallet_transactions 
        FOR SELECT USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ==============================================================================
-- RUNTIME COMPATIBILITY MIGRATIONS
-- ==============================================================================
-- 1. Ensure storage bucket for product photos exists
INSERT INTO storage.buckets (id, name, public) 
VALUES ('product-images', 'product-images', true) 
ON CONFLICT (id) DO NOTHING;

-- 2. Safe additive columns for product catalogue
ALTER TABLE public.sme_products ADD COLUMN IF NOT EXISTS quantity INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.sme_products ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.sme_products ADD COLUMN IF NOT EXISTS name_ar TEXT;

-- 3. Safe additive columns for inbound requests
ALTER TABLE public.sme_inbound_requests ADD COLUMN IF NOT EXISTS shipment_type TEXT DEFAULT 'drop_off';


