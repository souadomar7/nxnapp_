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
import '../../pages/checkout_page.dart';
import '../../models/invoice.dart';
import '../../pages/smart_inventory_stage.dart';

import '../../pages/settings/kyc_page.dart';
import '../../pages/operations/gate_pass_page.dart';
import '../../pages/operations/tracking_page.dart';

import '../../pages/copilot_page.dart';
import '../../pages/marketplace/seller_hub.dart';
import '../../pages/profile/wallet_page.dart';
import '../../pages/qr_scanner_page.dart';

/// Central route registry and RBAC redirect engine.
///
/// Role-based redirect matrix:
/// ┌───────────────┬──────────────────────────────────────────────────┐
/// │ Role          │ Redirect from guest-only routes                  │
/// ├───────────────┼──────────────────────────────────────────────────┤
/// │ guest         │ /shell, /book, /delivery → /login                │
/// │ customer      │ /login, /register, /onboarding → /shell          │
/// │ vendor        │ /login, /register, /onboarding → /shell          │
/// └───────────────┴──────────────────────────────────────────────────┘
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Resolves the current session synchronously from the live Supabase client.
  static UserSession get _session =>
      UserSession.fromSupabaseUser(
          Supabase.instance.client.auth.currentUser);

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
    '/copilot',
    '/seller-hub',
    '/wallet',
    '/qr-scanner',
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

      // 2. Authenticated users don't need to see login/register again
      if ((location == '/login' || location == '/register') &&
          session.isAuthenticated) {
        return '/shell';
      }

      // 3. Customer trying to book without UAE Pass → KYC gate
      if (location == '/book' && !session.canRentShelves) {
        return '/kyc';
      }

      // 4. Vendor portal without approved status → KYC/pending page
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
        path: '/checkout',
        builder: (_, state) {
          final invoice = state.extra as Invoice?;
          if (invoice != null) {
            return CheckoutPage(invoice: invoice);
          }
          return const PaymentsPage();
        },
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
      GoRoute(
        path: '/copilot',
        builder: (_, __) => const CopilotPage(),
      ),
      GoRoute(
        path: '/seller-hub',
        builder: (_, __) => const SellerHub(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (_, __) => const WalletPage(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (_, __) => const QrScannerPage(),
      ),
      GoRoute(
        path: '/payment/nxn-cash',
        builder: (_, __) => const PaymentsPage(),
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
