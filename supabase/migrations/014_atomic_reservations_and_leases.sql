-- ==============================================================================
-- Migration 014: Atomic Reservations, Warehouse Leases, and Inbound Gate Passes
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Ensure compatibility column on warehouses if needed
ALTER TABLE IF EXISTS public.warehouses ADD COLUMN IF NOT EXISTS monthly_shelf_rate_aed NUMERIC DEFAULT 100.0;
UPDATE public.warehouses SET monthly_shelf_rate_aed = price_per_shelf WHERE monthly_shelf_rate_aed IS NULL;

-- 1. Warehouse Leases Table (Holds & Confirmed Contracts)
CREATE TABLE IF NOT EXISTS public.warehouse_leases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    warehouse_id TEXT NOT NULL REFERENCES public.warehouses(id) ON DELETE RESTRICT,
    storage_type TEXT NOT NULL CHECK (storage_type IN ('ambient', 'temperature_controlled', 'cold_storage')),
    capacity_units INT NOT NULL CHECK (capacity_units > 0), -- e.g., Shelves or Pallets
    duration_months INT NOT NULL CHECK (duration_months > 0),
    status TEXT NOT NULL DEFAULT 'reserved' CHECK (status IN ('reserved', 'active', 'expired', 'canceled')),
    monthly_rate_aed NUMERIC(10, 2) NOT NULL,
    vat_amount_aed NUMERIC(10, 2) NOT NULL,
    total_amount_aed NUMERIC(10, 2) NOT NULL,
    payment_intent_id TEXT UNIQUE,
    idempotency_key UUID UNIQUE NOT NULL,
    hold_expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Inbound / Outbound Gate Passes Table
CREATE TABLE IF NOT EXISTS public.gate_passes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pass_code TEXT UNIQUE NOT NULL,
    lease_id UUID NOT NULL REFERENCES public.warehouse_leases(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    driver_name TEXT,
    driver_license TEXT,
    vehicle_plate TEXT,
    dock_gate TEXT DEFAULT 'Dock Gate 3',
    qr_signature TEXT NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    valid_until TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'issued' CHECK (status IN ('issued', 'docked', 'inspected', 'rejected', 'expired')),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Indexing for Fast Lookups & Expiry Sweeps
CREATE INDEX IF NOT EXISTS idx_leases_merchant ON public.warehouse_leases(merchant_id);
CREATE INDEX IF NOT EXISTS idx_leases_expiry ON public.warehouse_leases(status, hold_expires_at);
CREATE INDEX IF NOT EXISTS idx_gate_passes_code ON public.gate_passes(pass_code);

-- Enable Row Level Security
ALTER TABLE public.warehouse_leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gate_passes ENABLE ROW LEVEL SECURITY;

-- Lease Policies
DROP POLICY IF EXISTS "Merchants view their own leases" ON public.warehouse_leases;
CREATE POLICY "Merchants view their own leases"
    ON public.warehouse_leases FOR SELECT
    USING (auth.uid() = merchant_id OR public.is_admin());

DROP POLICY IF EXISTS "Merchants create their own leases" ON public.warehouse_leases;
CREATE POLICY "Merchants create their own leases"
    ON public.warehouse_leases FOR INSERT
    WITH CHECK (auth.uid() = merchant_id);

DROP POLICY IF EXISTS "Merchants/Service role update leases" ON public.warehouse_leases;
CREATE POLICY "Merchants/Service role update leases"
    ON public.warehouse_leases FOR UPDATE
    USING (auth.uid() = merchant_id OR auth.role() = 'service_role' OR public.is_admin());

-- Gate Pass Policies
DROP POLICY IF EXISTS "Merchants view their own gate passes" ON public.gate_passes;
CREATE POLICY "Merchants view their own gate passes"
    ON public.gate_passes FOR SELECT
    USING (auth.uid() = merchant_id OR public.is_admin());

DROP POLICY IF EXISTS "Merchants create their own gate passes" ON public.gate_passes;
CREATE POLICY "Merchants create their own gate passes"
    ON public.gate_passes FOR INSERT
    WITH CHECK (auth.uid() = merchant_id);

-- 3. Atomic Space Reservation RPC with Idempotency Replay & Storage Type Multiplier
CREATE OR REPLACE FUNCTION reserve_warehouse_capacity(
    p_warehouse_id TEXT,
    p_storage_type TEXT,
    p_capacity_units INT,
    p_duration_months INT,
    p_idempotency_key UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_existing_lease public.warehouse_leases%ROWTYPE;
    v_monthly_rate NUMERIC;
    v_multiplier NUMERIC;
    v_total_shelves INT;
    v_active_units INT;
    v_lease_id UUID;
    v_base_total NUMERIC;
    v_vat NUMERIC;
    v_grand_total NUMERIC;
    v_hold_expiration TIMESTAMPTZ;
BEGIN
    -- 1. Idempotency Check: Return existing reservation if replayed
    SELECT * INTO v_existing_lease
    FROM public.warehouse_leases
    WHERE idempotency_key = p_idempotency_key;

    IF FOUND THEN
        RETURN jsonb_build_object(
            'success', true,
            'replayed', true,
            'lease_id', v_existing_lease.id,
            'status', v_existing_lease.status,
            'total_amount_aed', v_existing_lease.total_amount_aed,
            'hold_expires_at', v_existing_lease.hold_expires_at
        );
    END IF;

    -- 2. Lock Warehouse Row for Concurrency Check
    SELECT COALESCE(monthly_shelf_rate_aed, price_per_shelf, 100.0), COALESCE(total_shelves, 100)
    INTO v_monthly_rate, v_total_shelves
    FROM public.warehouses
    WHERE id = p_warehouse_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Warehouse facility not found');
    END IF;

    -- 3. Check Real-Time Availability (Active Leases + Non-Expired Holds)
    SELECT COALESCE(SUM(capacity_units), 0) INTO v_active_units
    FROM public.warehouse_leases
    WHERE warehouse_id = p_warehouse_id
      AND (
          status = 'active' 
          OR (status = 'reserved' AND hold_expires_at > now())
      );

    IF (v_active_units + p_capacity_units) > v_total_shelves THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Insufficient capacity: Requested space is currently locked or occupied'
        );
    END IF;

    -- 4. Apply Storage-Type Multiplier & Financials (UAE FTA Compliant 5% VAT)
    v_multiplier := CASE p_storage_type
        WHEN 'cold_storage' THEN 1.45
        WHEN 'temperature_controlled' THEN 1.20
        ELSE 1.00
    END;

    v_base_total := (p_capacity_units * (v_monthly_rate * v_multiplier)) * p_duration_months;
    v_vat := ROUND(v_base_total * 0.05, 2);
    v_grand_total := v_base_total + v_vat;
    v_hold_expiration := now() + INTERVAL '10 minutes';

    -- 5. Insert Atomic Hold
    INSERT INTO public.warehouse_leases (
        merchant_id,
        warehouse_id,
        storage_type,
        capacity_units,
        duration_months,
        status,
        monthly_rate_aed,
        vat_amount_aed,
        total_amount_aed,
        idempotency_key,
        hold_expires_at
    ) VALUES (
        auth.uid(),
        p_warehouse_id,
        p_storage_type,
        p_capacity_units,
        p_duration_months,
        'reserved',
        v_monthly_rate * v_multiplier,
        v_vat,
        v_grand_total,
        p_idempotency_key,
        v_hold_expiration
    ) RETURNING id INTO v_lease_id;

    RETURN jsonb_build_object(
        'success', true,
        'replayed', false,
        'lease_id', v_lease_id,
        'status', 'reserved',
        'total_amount_aed', v_grand_total,
        'hold_expires_at', v_hold_expiration
    );
END;
$$;

-- 4. Secure Payment Intent & Lease Confirmation RPC with Strict Amount Validation
CREATE OR REPLACE FUNCTION confirm_lease_and_issue_gatepass(
    p_lease_id UUID,
    p_payment_intent_id TEXT,
    p_paid_amount_cents BIGINT,
    p_driver_name TEXT DEFAULT 'Assigned Fleet Driver',
    p_vehicle_plate TEXT DEFAULT 'DXB-FLEET-1',
    p_driver_license TEXT DEFAULT 'UAE-DL-PENDING'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lease public.warehouse_leases%ROWTYPE;
    v_pass_code TEXT;
    v_qr_sig TEXT;
    v_gate_pass_id UUID;
    v_expected_cents BIGINT;
BEGIN
    -- 1. Fetch lease
    SELECT * INTO v_lease
    FROM public.warehouse_leases
    WHERE id = p_lease_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Lease not found');
    END IF;

    -- 2. Verify amount (prevent tampering or currency truncation)
    v_expected_cents := (v_lease.total_amount_aed * 100)::BIGINT;
    IF (p_paid_amount_cents != v_expected_cents) THEN
        RETURN jsonb_build_object(
            'success', false, 
            'error', 'Paid amount does not match lease total. Expected ' || v_expected_cents || ' cents, received ' || p_paid_amount_cents
        );
    END IF;

    -- 3. Confirm lease
    UPDATE public.warehouse_leases
    SET status = 'active',
        payment_intent_id = p_payment_intent_id,
        updated_at = now()
    WHERE id = p_lease_id;

    -- 4. Generate Gate Pass
    v_pass_code := 'GP-' || UPPER(SUBSTRING(gen_random_uuid()::text, 1, 8));
    v_qr_sig := 'NXN-PASS:' || v_pass_code || ':' || p_lease_id::text;

    INSERT INTO public.gate_passes (
        pass_code,
        lease_id,
        merchant_id,
        driver_name,
        driver_license,
        vehicle_plate,
        dock_gate,
        qr_signature,
        valid_from,
        valid_until,
        status
    ) VALUES (
        v_pass_code,
        p_lease_id,
        v_lease.merchant_id,
        p_driver_name,
        p_driver_license,
        p_vehicle_plate,
        'Dock Gate 3',
        v_qr_sig,
        now(),
        now() + (v_lease.duration_months || ' months')::INTERVAL,
        'issued'
    ) RETURNING id INTO v_gate_pass_id;

    RETURN jsonb_build_object(
        'success', true,
        'lease_id', p_lease_id,
        'status', 'active',
        'gate_pass_id', v_gate_pass_id,
        'pass_code', v_pass_code,
        'qr_signature', v_qr_sig
    );
END;
$$;

-- 5. Passive Expiry Cleanup (Run in Supabase SQL editor with pg_cron)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        PERFORM cron.schedule(
            'expire_abandoned_warehouse_holds',
            '*/5 * * * *',
            $cron$
                UPDATE public.warehouse_leases
                SET status = 'expired'
                WHERE status = 'reserved'
                  AND hold_expires_at < now();
            $cron$
        );
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- Fallback if pg_cron is not enabled in local environments
    NULL;
END;
$$;
