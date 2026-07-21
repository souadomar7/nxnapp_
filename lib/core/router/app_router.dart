import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/user_session.dart';

import '../../pages/home_shell.dart';
import '../../pages/login.dart';
import '../../pages/registration_page.dart';
import '../../pages/splash_page.dart';
import '../../pages/terms_and_conditions.dart';
import '../../pages/onboarding/service_overview_page.dart';
import '../../pages/onboarding/profile_setup_page.dart';
import '../../pages/booking_page.dart';
import '../../pages/request_delivery_page.dart';
import '../../pages/payment_page.dart';
import '../../pages/smart_inventory_stage.dart';
import '../../pages/admin/admin_dashboard.dart';
import '../../pages/admin/admin_login_page.dart';
import '../../pages/admin/damage_inspection_page.dart';
import '../../pages/admin/vendor_approval_page.dart';
import '../../pages/payment/nxn_cash_payment_page.dart';

import '../../pages/settings/kyc_page.dart';
import '../../pages/operations/gate_pass_page.dart';
import '../../pages/operations/tracking_page.dart';

/// Central route registry and RBAC redirect engine.
///
/// Role-based redirect matrix:
/// ┌───────────────┬──────────────────────────────────────────────────┐
/// │ Role          │ Redirect from guest-only routes                  │
/// ├───────────────┼──────────────────────────────────────────────────┤
/// │ guest         │ /shell, /book, /delivery → /login                │
/// │ customer      │ /login, /register, /onboarding → /shell          │
/// │ vendor        │ /login, /register, /onboarding → /shell          │
/// │ whAdmin       │ /login, /register, /onboarding → /admin          │
/// │ superAdmin    │ /login, /register, /onboarding → /admin          │
/// └───────────────┴──────────────────────────────────────────────────┘
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Resolves the current session synchronously from the live Supabase client.
  static UserSession get _session =>
      UserSession.fromSupabaseUser(
          Supabase.instance.client.auth.currentUser);

  /// Routes restricted to warehouse admin and super admin only.
  static const _adminRoutes = {'/admin', '/admin/login'};

  /// Routes requiring at minimum a verified customer session.
  static const _authenticatedRoutes = {
    '/shell',
    '/book',
    '/delivery',
    '/inventory',
    '/gate-pass',
    '/tracking',
    '/kyc',
    '/payments',
  };

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,

    // ── Global RBAC redirect guard ─────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) async {
      final location = state.uri.path;
      final session = _session;

      // 1. Guest on authenticated route → login
      if (session.isGuest && _authenticatedRoutes.contains(location)) {
        return '/login';
      }

      // 2. Guest or customer attempting admin routes → denied
      if (_adminRoutes.contains(location) && !session.canAccessWms) {
        return session.isGuest ? '/login' : '/shell';
      }

      // 3. Authenticated users don't need to see login/register again
      if ((location == '/login' || location == '/register') &&
          session.isAuthenticated) {
        return session.canAccessWms ? '/admin' : '/shell';
      }

      // 4. Customer trying to book without UAE Pass → KYC gate
      if (location == '/book' && !session.canRentShelves) {
        return '/kyc';
      }

      // 5. Vendor portal without approved status → KYC/pending page
      if (location == '/vendor-portal' && !session.canListProducts) {
        return '/kyc';
      }

      return null; // no redirect needed
    },

    routes: [
      // ── Public / unauthenticated ──────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const ServiceOverviewPage(),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const TermsAndConditionsPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegistrationPage(),
      ),

      // ── Authenticated (customer+) ─────────────────────────────────────────
      GoRoute(
        path: '/shell',
        builder: (_, __) => const HomeShell(),
      ),
      GoRoute(
        path: '/book',
        builder: (_, __) => const BookingPage(),
      ),
      GoRoute(
        path: '/delivery',
        builder: (_, __) => const RequestDeliveryPage(),
      ),
      GoRoute(
        path: '/payments',
        builder: (_, __) => const PaymentsPage(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (_, __) => const SmartInventoryStageEN(),
      ),
      GoRoute(
        path: '/gate-pass',
        builder: (_, __) => const GatePassPage(),
      ),
      GoRoute(
        path: '/tracking',
        builder: (_, __) => const TrackingPage(),
      ),
      GoRoute(
        path: '/kyc',
        builder: (_, __) => const KYCPage(),
      ),

      // ── Warehouse Admin (whAdmin + superAdmin) ────────────────────────────
      GoRoute(
        path: '/admin/login',
        builder: (_, __) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/damage-inspection',
        builder: (_, __) => const DamageInspectionPage(),
      ),
      GoRoute(
        path: '/admin/vendor-approval',
        builder: (_, __) => const VendorApprovalPage(),
      ),
      GoRoute(
        path: '/payment/nxn-cash',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return NxnCashPaymentPage(
            orderId: extra['orderId']?.toString() ?? 'ORD-001',
            amount: (extra['amount'] as num?)?.toDouble() ?? 0.0,
            description: extra['description']?.toString() ?? 'NXN Service Payment',
          );
        },
      ),

      // ── Profile setup (post UAE Pass callback) ────────────────────────────
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) {
          final data = state.extra as Map<String, String>? ?? {};
          return ProfileSetupPage(uaePassData: data);
        },
      ),
    ],

    // ── Error fallback ──────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.path}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/splash'),
              child: const Text('Return Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
