-- ==============================================================================
-- 013_PROFILE_PERSISTENCE_AND_ORDER_SECURITY.SQL
-- Resolves P0 audit findings:
-- 1. Adds missing INSERT RLS policy on sme_sellers for authenticated users.
-- 2. Hardens buyer_orders so clients cannot set payment_status = 'paid' on INSERT.
-- 3. Adds secure function for merchant product price and inventory management.
-- ==============================================================================

-- 1. Ensure sme_sellers allows authenticated users to insert their own profile
DROP POLICY IF EXISTS "Sellers can insert their own profile" ON sme_sellers;
CREATE POLICY "Sellers can insert their own profile"
  ON sme_sellers FOR INSERT
  WITH CHECK (id = auth.uid() OR auth.role() = 'service_role');

-- Ensure profiles allows insert/upsert for authenticated users
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (id = auth.uid() OR auth.role() = 'service_role');

-- 2. Harden buyer_orders: prevent client insertion of payment_status = 'paid'
ALTER TABLE IF EXISTS buyer_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Buyers can create orders" ON buyer_orders;
CREATE POLICY "Buyers can create orders"
  ON buyer_orders FOR INSERT
  WITH CHECK (
    (auth.uid() IS NULL OR buyer_id = auth.uid())
    AND payment_status IN ('pending', 'awaiting_payment')
  );

DROP POLICY IF EXISTS "Service role can update order payment status" ON buyer_orders;
CREATE POLICY "Service role can update order payment status"
  ON buyer_orders FOR UPDATE
  USING (auth.role() = 'service_role' OR public.is_admin())
  WITH CHECK (auth.role() = 'service_role' OR public.is_admin());

-- 3. Secure Stored Procedure for Merchant Product Price and Inventory Management
CREATE OR REPLACE FUNCTION public.update_merchant_product_price(
  p_product_id TEXT,
  p_new_price NUMERIC,
  p_new_quantity INT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_seller_id UUID;
  v_updated_product JSONB;
BEGIN
  -- Validate caller is authenticated
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Validate price
  IF p_new_price <= 0 THEN
    RAISE EXCEPTION 'Price must be greater than zero';
  END IF;

  -- Check product ownership
  SELECT seller_id INTO v_seller_id
  FROM sme_products
  WHERE id = p_product_id;

  IF v_seller_id IS NULL THEN
    RAISE EXCEPTION 'Product not found: %', p_product_id;
  END IF;

  IF v_seller_id != auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: You do not own this product';
  END IF;

  -- Update product price
  UPDATE sme_products
  SET price = p_new_price
  WHERE id = p_product_id;

  -- Optionally update inventory stock if specified
  IF p_new_quantity IS NOT NULL AND p_new_quantity >= 0 THEN
    UPDATE sme_inventory
    SET quantity = p_new_quantity,
        total_value = p_new_quantity * p_new_price
    WHERE product_id = p_product_id;
  END IF;

  SELECT to_jsonb(p.*) INTO v_updated_product
  FROM sme_products p
  WHERE p.id = p_product_id;

  RETURN jsonb_build_object(
    'success', true,
    'product_id', p_product_id,
    'new_price', p_new_price,
    'product', v_updated_product
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
