import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/user_role.dart';
import '../auth/user_session.dart';

// Placeholders for clean modular views in routing context
class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Onboarding View')));
}

class LoginView extends StatelessWidget {
  const LoginView({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login View')));
}

class ExploratoryDirectoryView extends StatelessWidget {
  const ExploratoryDirectoryView({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Exploratory Directory View')));
}

class MerchantDashboardParent extends StatelessWidget {
  const MerchantDashboardParent({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Merchant Dashboard Parent')));
}

class WarehouseScannerParent extends StatelessWidget {
  const WarehouseScannerParent({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Warehouse Scanner Parent')));
}

class AppRouter {
  final UserSession _session;

  AppRouter(this._session);

  late final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.uri.toString();
      final isGuestOnlyRoute = location == '/onboarding' || location == '/directory' || location == '/login';

      // 1. Redirect guests if they try to access operational routes
      if (_session.role == UserRole.guest && !isGuestOnlyRoute) {
        return '/login';
      }

      // 2. Redirect logged-in roles from guest-only screens to their dashboards
      if (_session.role == UserRole.merchant && isGuestOnlyRoute) {
        return '/merchant-dashboard';
      }
      if (_session.role == UserRole.operator && isGuestOnlyRoute) {
        return '/operator-dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/directory',
        builder: (context, state) => const ExploratoryDirectoryView(),
      ),
      GoRoute(
        path: '/merchant-dashboard',
        builder: (context, state) => const MerchantDashboardParent(),
      ),
      GoRoute(
        path: '/operator-dashboard',
        builder: (context, state) => const WarehouseScannerParent(),
      ),
    ],
  );
}
