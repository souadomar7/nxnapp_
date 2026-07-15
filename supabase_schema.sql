-- ==============================================================================
-- NXN Hub: COMPLETE CLOUD DATABASE SCHEMA FOR SUPABASE
-- Run this script in the Supabase SQL Editor to set up your entire application.
-- ==============================================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 1. Static Entities & Profiles
-- ==============================================================================

-- A. WAREHOUSES DIRECTORY
CREATE TABLE IF NOT EXISTS warehouses (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    total_shelves INTEGER NOT NULL DEFAULT 100,
    address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Pre-populate default warehouses if empty
INSERT INTO warehouses (id, name, total_shelves, address) VALUES
('dxb', 'Dubai Central Warehouse', 200, 'Al Quoz, Dubai'),
('auh', 'Abu Dhabi central Warehouse', 150, 'Mussafah, Abu Dhabi'),
('shj', 'Sharjah Central Warehouse', 100, 'Industrial Area, Sharjah'),
('aln', 'Al Ain Central Warehouse', 100, 'Sanaiya, Al Ain')
ON CONFLICT (id) DO NOTHING;

-- B. VERIFIED MARKETPLACE SHOPS
CREATE TABLE IF NOT EXISTS marketplace_shops (
    id TEXT PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    shop_name TEXT NOT NULL,
    license_name TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(seller_id)
);


-- ==============================================================================
-- 2. Products & Inventory
-- ==============================================================================

-- C. PRODUCTS CATALOGUE
CREATE TABLE IF NOT EXISTS sme_products (
    id TEXT PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- D. PHYSICAL SHELF INVENTORY
CREATE TABLE IF NOT EXISTS sme_inventory (
    id TEXT PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    product_id TEXT REFERENCES sme_products(id) ON DELETE SET NULL,
    shelf_id TEXT,
    quantity INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL, -- 'in_stock', 'damaged', 'out_of_stock'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);


-- ==============================================================================
-- 3. Warehouse Subscriptions (Rentals) & Operations
-- ==============================================================================

-- E. RENTED SPACE SUBSCRIPTIONS
CREATE TABLE IF NOT EXISTS sme_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    warehouse_id TEXT REFERENCES warehouses(id) ON DELETE CASCADE NOT NULL,
    shelves_count INTEGER NOT NULL DEFAULT 1,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- F. INBOUND GATE PASS / DELIVERY REQUESTS (For receiving goods)
CREATE TABLE IF NOT EXISTS sme_inbound_requests (
    id TEXT PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    expected_date TIMESTAMP WITH TIME ZONE,
    item_count INTEGER,
    gate_pass_code TEXT,
    labor_count INTEGER DEFAULT 0 NOT NULL,
    visual_inspection_requested BOOLEAN DEFAULT false NOT NULL,
    status TEXT NOT NULL, -- 'pending', 'received', 'completed'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);


-- ==============================================================================
-- 4. Invoices, Payments, Outbound Orders & Activities
-- ==============================================================================

-- G. GLOBAL BILLING INVOICES
CREATE TABLE IF NOT EXISTS sme_invoices (
    id TEXT PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    invoice_number TEXT NOT NULL,
    warehouse_name TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    vat NUMERIC(10,2) NOT NULL,
    worker_fee NUMERIC(10,2) DEFAULT 0.0 NOT NULL,
    paid BOOLEAN DEFAULT false NOT NULL,
    type TEXT NOT NULL, -- 'rental', 'delivery', 'generic'
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- H. OUTBOUND ORDERS (For shipment & courier delivery)
CREATE TABLE IF NOT EXISTS sme_orders (
    id TEXT PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    customer_name TEXT,
    customer_address TEXT,
    delivery_method TEXT,
    status TEXT NOT NULL, -- 'pending', 'shipped', 'delivered', 'completed'
    total_amount NUMERIC(10,2) DEFAULT 0.0 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- I. SYSTEM LOG ACTIVITY HISTORIES
CREATE TABLE IF NOT EXISTS dashboard_activities (
    id TEXT PRIMARY KEY,
    seller_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    type TEXT NOT NULL, -- 'rental', 'delivery', 'inventory', 'invoice'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);


-- ==============================================================================
-- 5. Enable Row-Level Security (RLS) & Define Access Policies
-- ==============================================================================

-- Enable RLS on all operational tables
ALTER TABLE marketplace_shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_inbound_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE sme_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_activities ENABLE ROW LEVEL SECURITY;

-- 1. PUBLIC ACCESS POLICIES (Read-only for buyer-facing content)
CREATE POLICY "Allow public read access to verified shops" 
ON marketplace_shops FOR SELECT USING (true);

CREATE POLICY "Allow public read access to products" 
ON sme_products FOR SELECT USING (true);

-- 2. MERCHANT/SELLER DATA ISOLATION POLICIES (Users manage their own items)
CREATE POLICY "Allow sellers to manage their own shop profile" 
ON marketplace_shops FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Allow sellers to manage their own products" 
ON sme_products FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Allow sellers to view/manage their inventory" 
ON sme_inventory FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Allow sellers to view/manage their subscriptions" 
ON sme_subscriptions FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Allow sellers to view/manage inbound requests" 
ON sme_inbound_requests FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Allow sellers to view/manage their invoices" 
ON sme_invoices FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Allow sellers to view/manage their orders" 
ON sme_orders FOR ALL USING (auth.uid() = seller_id);

CREATE POLICY "Allow sellers to view their dashboard activity logs" 
ON dashboard_activities FOR ALL USING (auth.uid() = seller_id);
