-- ==============================================================================
-- NXN PLATFORM: 100% CLEAN DATABASE RESET SCRIPT (ZERO DDL / NO FK CONFLICTS)
-- Simply deletes all rows from all app data tables safely.
-- ==============================================================================

DO $$
BEGIN
    -- 1. Disable triggers and foreign key checks for fast clean deletion
    SET session_replication_role = 'replica';

    -- 2. Clear products, inventory & orders
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'buyer_orders') THEN
        DELETE FROM public.buyer_orders;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sme_orders') THEN
        DELETE FROM public.sme_orders;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'orders') THEN
        DELETE FROM public.orders;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sme_inventory') THEN
        DELETE FROM public.sme_inventory;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sme_products') THEN
        DELETE FROM public.sme_products;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sme_inbound_requests') THEN
        DELETE FROM public.sme_inbound_requests;
    END IF;

    -- 3. Clear contracts, invoices, notifications & history
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sme_subscriptions') THEN
        DELETE FROM public.sme_subscriptions;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sme_invoices') THEN
        DELETE FROM public.sme_invoices;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'dashboard_activities') THEN
        DELETE FROM public.dashboard_activities;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        DELETE FROM public.notifications;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'dock_gate_passes') THEN
        DELETE FROM public.dock_gate_passes;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'marketplace_shops') THEN
        DELETE FROM public.marketplace_shops;
    END IF;

    -- 4. Clear wallet transactions & reset balances
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payout_audit_logs') THEN
        DELETE FROM public.payout_audit_logs;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'wallet_transactions') THEN
        DELETE FROM public.wallet_transactions;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payout_requests') THEN
        DELETE FROM public.payout_requests;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'wallets') THEN
        DELETE FROM public.wallets;
    END IF;

    -- 5. Re-enable normal constraints
    SET session_replication_role = 'origin';

    RAISE NOTICE '✅ ALL NXN DATA TABLES HAVE BEEN CLEARED SUCCESSFULLY!';
END $$;
