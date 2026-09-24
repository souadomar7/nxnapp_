-- ============================================================
-- NXN App — Database Migration (v2 to v3)
-- Run this in Supabase SQL Editor (Dashboard -> SQL Editor)
-- Safe to run multiple times — all operations are idempotent.
-- ============================================================

-- 1. WAREHOUSE SEED DATA
INSERT INTO warehouses (id, name, name_ar, emirate, address, total_shelves, price_per_shelf) VALUES
  ('dxb', 'Dubai Central Warehouse',    'مستودع دبي المركزي',        'Dubai',     'Al Quoz, Dubai',             200, 100.0),
  ('auh', 'Abu Dhabi Central Warehouse','مستودع أبوظبي المركزي',     'Abu Dhabi', 'Mussafah, Abu Dhabi',        150, 100.0),
  ('shj', 'Sharjah Central Warehouse',  'مستودع الشارقة المركزي',    'Sharjah',   'Industrial Area, Sharjah',   100, 100.0),
  ('aln', 'Al Ain Central Warehouse',   'مستودع العين المركزي',      'Al Ain',    'Sanaiya, Al Ain',            100, 100.0),
  ('dxb-2', 'Dubai South Warehouse',         'مستودع دبي الجنوب',        'Dubai',     'Dubai South Logistics District', 150, 100.0),
  ('dxb-3', 'Jebel Ali Free Zone Warehouse', 'مستودع جبل علي',           'Dubai',     'Jebel Ali Free Zone, Dubai',     120, 110.0),
  ('auh-2', 'Khalifa Industrial Zone Warehouse','مستودع كيزاد',           'Abu Dhabi', 'KIZAD, Abu Dhabi',               100, 105.0),
  ('shj-2', 'Hamriyah Free Zone Warehouse',  'مستودع منطقة حمرية الحرة', 'Sharjah',   'Hamriyah Free Zone, Sharjah',     80, 105.0),
  ('aln-2', 'Al Ain South Warehouse',        'مستودع العين الجنوبي',     'Al Ain',    'Al Jimi, Al Ain',                 60,  95.0)
ON CONFLICT (id) DO NOTHING;

-- 2. sme_sellers new columns
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS license_owner_name TEXT;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS license_name TEXT;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS uae_pass_uuid TEXT;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS selected_warehouse_id TEXT REFERENCES warehouses(id) ON DELETE SET NULL;
ALTER TABLE sme_sellers ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMP WITH TIME ZONE;

-- 3. sme_products new columns
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS name_ar TEXT;
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS quantity INTEGER NOT NULL DEFAULT 0;
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE sme_products ADD COLUMN IF NOT EXISTS hidden_reason TEXT;

-- 4. sme_inbound_requests pickup fields
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS shipment_type TEXT NOT NULL DEFAULT 'drop_off';
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS pickup_location_name TEXT;
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS pickup_address TEXT;
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS goods_type TEXT;
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS pickup_contact_name TEXT;
ALTER TABLE sme_inbound_requests ADD COLUMN IF NOT EXISTS pickup_contact_phone TEXT;

-- 5. sme_orders new columns + expanded status
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES sme_products(id) ON DELETE SET NULL;
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS customer_phone TEXT;
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS customer_email TEXT;
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS quantity INTEGER DEFAULT 1 NOT NULL;
ALTER TABLE sme_orders ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE sme_orders DROP CONSTRAINT IF EXISTS sme_orders_status_check;
ALTER TABLE sme_orders ADD CONSTRAINT sme_orders_status_check CHECK (status IN (
  'pending','confirmed','preparing','ready_for_shipment',
  'shipped','picked','out_for_delivery','delivered','completed','cancelled'
));

-- 6. marketplace_shops new columns
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT false NOT NULL;
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS featured_until TIMESTAMP WITH TIME ZONE;
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS license_document_url TEXT;
ALTER TABLE marketplace_shops ADD COLUMN IF NOT EXISTS shop_description TEXT;

-- 7. notifications table (NEW)
CREATE TABLE IF NOT EXISTS notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  type        TEXT NOT NULL DEFAULT 'general',
  is_read     BOOLEAN DEFAULT false NOT NULL,
  metadata    JSONB,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()) NOT NULL
);
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users see their own notifications" ON notifications;
CREATE POLICY "Users see their own notifications"
  ON notifications FOR ALL USING (auth.uid() = user_id);

-- 8. buyer_orders RLS policies (table may already exist)
ALTER TABLE buyer_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Sellers see buyer orders for their products" ON buyer_orders;
DROP POLICY IF EXISTS "Anyone can place a buyer order" ON buyer_orders;
DROP POLICY IF EXISTS "Sellers can update buyer order status" ON buyer_orders;
CREATE POLICY "Sellers see buyer orders for their products"
  ON buyer_orders FOR SELECT USING (auth.uid() = seller_id);
CREATE POLICY "Anyone can place a buyer order"
  ON buyer_orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Sellers can update buyer order status"
  ON buyer_orders FOR UPDATE USING (auth.uid() = seller_id);

-- 9. Update signup trigger to include email
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
