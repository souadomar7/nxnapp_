-- ==============================================================================
-- NXN LOGISTICS & MARKETPLACE PLATFORM — DATABASE MIGRATION SCRIPT
-- Version: 1.0.0
-- Standard: PostgreSQL 14+ / Supabase Row-Level Security (RLS)
-- ==============================================================================

BEGIN;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. USERS & IDENTITY EXTENSION (ENUMS & CORE ATTRIBUTES)
-- ------------------------------------------------------------------------------

CREATE TYPE user_role_enum AS ENUM (
  'ROLE_GUEST',
  'ROLE_CUSTOMER',
  'ROLE_VENDOR',
  'ROLE_WH_ADMIN',
  'ROLE_SUPER_ADMIN'
);

CREATE TYPE vendor_status_enum AS ENUM (
  'NONE',
  'PENDING_APPROVAL',
  'APPROVED',
  'REJECTED'
);

CREATE TYPE condition_status_enum AS ENUM (
  'PENDING_INTAKE',
  'STORED',
  'OUT_FOR_DELIVERY',
  'DAMAGED'
);

CREATE TYPE payment_status_enum AS ENUM (
  'PENDING',
  'PAID',
  'FAILED',
  'REFUNDED'
);

-- ------------------------------------------------------------------------------
-- 2. VENDOR PROFILES TABLE
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS vendor_profiles (
    vendor_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL,
    trade_license_number VARCHAR(100) UNIQUE NOT NULL,
    trade_license_url TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT FALSE,
    rejection_reason TEXT,
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 3. WAREHOUSES TABLE
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouses (
    warehouse_id VARCHAR(50) PRIMARY KEY, -- e.g., 'dxb', 'auh', 'shj', 'aln'
    location_name VARCHAR(100) NOT NULL,
    emirate VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    max_shelf_capacity INT NOT NULL DEFAULT 100,
    current_used_shelves INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT check_capacity CHECK (current_used_shelves <= max_shelf_capacity)
);

-- Seed Initial Warehouses
INSERT INTO warehouses (warehouse_id, location_name, emirate, address, max_shelf_capacity, current_used_shelves)
VALUES 
  ('dxb', 'Dubai Central Logistics Hub', 'Dubai', 'Al Quoz Industrial Area 3', 200, 0),
  ('auh', 'Abu Dhabi Gateway Terminal', 'Abu Dhabi', 'Mussafah Industrial Area', 150, 0),
  ('shj', 'Sharjah Cargo Hub', 'Sharjah', 'Industrial Area 12', 100, 0),
  ('aln', 'Al Ain Distribution Center', 'Abu Dhabi', 'Niyadat Logistics Zone', 80, 0)
ON CONFLICT (warehouse_id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 4. SHELF RENTALS TABLE
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shelf_rentals (
    rental_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    warehouse_id VARCHAR(50) NOT NULL REFERENCES warehouses(warehouse_id),
    shelf_quantity INT NOT NULL CHECK (shelf_quantity > 0),
    duration_months INT NOT NULL DEFAULT 1 CHECK (duration_months > 0),
    base_cost NUMERIC(10, 2) NOT NULL,
    requires_workers BOOLEAN DEFAULT FALSE,
    worker_fee NUMERIC(10, 2) DEFAULT 0.00,
    prep_time_slot TIMESTAMPTZ,
    total_paid NUMERIC(10, 2) NOT NULL,
    payment_status payment_status_enum DEFAULT 'PENDING',
    condition_status condition_status_enum DEFAULT 'PENDING_INTAKE',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 5. DAMAGE INSPECTION PHOTOS TABLE
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS damage_inspection_photos (
    inspection_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rental_id UUID NOT NULL REFERENCES shelf_rentals(rental_id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    flagged_by UUID NOT NULL REFERENCES auth.users(id),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 6. CASH PAYMENT REFERENCES TABLE (NXN POSTAL CASH)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS cash_payment_references (
    reference_id VARCHAR(50) PRIMARY KEY, -- e.g., 'NXN-AB12CD34'
    order_id VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    amount NUMERIC(10, 2) NOT NULL,
    description TEXT,
    status payment_status_enum DEFAULT 'PENDING',
    expires_at TIMESTAMPTZ NOT NULL,
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 7. MARKETPLACE PRODUCTS TABLE
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS marketplace_products (
    product_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(vendor_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    price_aed NUMERIC(10, 2) NOT NULL CHECK (price_aed >= 0),
    stock_quantity INT DEFAULT 0,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 8. ATOMIC STORED PROCEDURES & RPCs
-- ------------------------------------------------------------------------------

-- Increment used shelves atomically
CREATE OR REPLACE FUNCTION increment_used_shelves(p_warehouse_id VARCHAR(50), p_quantity INT)
RETURNS VOID AS $$
BEGIN
    UPDATE warehouses
    SET current_used_shelves = current_used_shelves + p_quantity
    WHERE warehouse_id = p_warehouse_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC to approve/reject vendor
CREATE OR REPLACE FUNCTION set_vendor_status(
    target_user_id UUID,
    new_status VARCHAR,
    new_role VARCHAR
)
RETURNS VOID AS $$
BEGIN
    UPDATE auth.users
    SET raw_app_meta_data = 
        coalesce(raw_app_meta_data, '{}'::jsonb) || 
        jsonb_build_object('vendor_status', new_status, 'role', new_role)
    WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ------------------------------------------------------------------------------
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------

ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE shelf_rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE damage_inspection_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_payment_references ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_products ENABLE ROW LEVEL SECURITY;

-- Public read for products
CREATE POLICY "Public products view" ON marketplace_products FOR SELECT USING (is_active = true);

-- Users view their own rentals
CREATE POLICY "Renters view own shelf rentals" ON shelf_rentals FOR SELECT USING (auth.uid() = user_id);

-- Admins view all
CREATE POLICY "Admins full access to rentals" ON shelf_rentals FOR ALL USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('wh_admin', 'super_admin', 'ROLE_WH_ADMIN', 'ROLE_SUPER_ADMIN')
);

COMMIT;
