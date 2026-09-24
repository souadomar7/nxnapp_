-- ==============================================================================
-- 009_RLS_HARDENING.SQL
-- Tighten existing RLS policies on canonical tables so client cannot bypass
-- server verification (e.g. self-approving shops, verifying own sellers).
-- ==============================================================================

-- 1. Hardening sme_sellers
ALTER TABLE sme_sellers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Sellers can manage their own profile" ON sme_sellers;
DROP POLICY IF EXISTS "Sellers can view their own profile" ON sme_sellers;
DROP POLICY IF EXISTS "Sellers can update their own non-privileged profile" ON sme_sellers;

CREATE POLICY "Sellers can view their own profile"
  ON sme_sellers FOR SELECT
  USING (id = auth.uid() OR public.is_admin());

-- Users can update contact & business info, but CANNOT self-verify
CREATE POLICY "Sellers can update their own non-privileged profile"
  ON sme_sellers FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND is_verified = (SELECT is_verified FROM sme_sellers WHERE id = auth.uid())
  );

-- 2. Hardening marketplace_shops
ALTER TABLE marketplace_shops ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Sellers manage their own shop" ON marketplace_shops;
DROP POLICY IF EXISTS "Sellers can update own shop details" ON marketplace_shops;

-- Public can read approved shops
DROP POLICY IF EXISTS "Public can browse verified shops" ON marketplace_shops;
CREATE POLICY "Public can browse verified shops"
  ON marketplace_shops FOR SELECT
  USING (is_approved = true OR seller_id = auth.uid() OR public.is_admin());

-- Sellers can update details, but CANNOT flip is_approved or is_featured
CREATE POLICY "Sellers can update own shop details"
  ON marketplace_shops FOR UPDATE
  USING (seller_id = auth.uid())
  WITH CHECK (
    seller_id = auth.uid()
    AND is_approved = (SELECT is_approved FROM marketplace_shops WHERE seller_id = auth.uid())
    AND is_featured = (SELECT is_featured FROM marketplace_shops WHERE seller_id = auth.uid())
  );
