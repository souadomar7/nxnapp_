import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nxnapp/core/auth/user_role.dart';
import 'package:nxnapp/core/auth/user_session.dart';
import 'package:nxnapp/core/router/app_router.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

UserSession guestSession() => const UserSession(role: UserRole.guest);
UserSession merchantSession() => const UserSession(role: UserRole.merchant);
UserSession operatorSession() => const UserSession(role: UserRole.operator);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('Router Guard – Guest Deep Link Bypass Tests', () {
    late GoRouter router;

    setUp(() {
      router = AppRouter(guestSession()).router;
    });

    tearDown(() {
      router.dispose();
    });

    testWidgets(
      'Guest navigating to /merchant-dashboard is redirected to /login',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Attempt deep link bypass to merchant dashboard
        router.go('/merchant-dashboard');
        await tester.pumpAndSettle();

        // Router must have redirected to /login
        expect(router.routeInformationProvider.value.uri.toString(), '/login');
      },
    );

    testWidgets(
      'Guest navigating to /operator-dashboard is redirected to /login',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.go('/operator-dashboard');
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.toString(), '/login');
      },
    );
  });

  group('Router Guard – Merchant Deep Link Bypass Tests', () {
    late GoRouter router;

    setUp(() {
      router = AppRouter(merchantSession()).router;
    });

    tearDown(() {
      router.dispose();
    });

    testWidgets(
      'Merchant navigating to /onboarding is redirected to /merchant-dashboard',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.go('/onboarding');
        await tester.pumpAndSettle();

        expect(
          router.routeInformationProvider.value.uri.toString(),
          '/merchant-dashboard',
        );
      },
    );

    testWidgets(
      'Merchant navigating to /login is redirected to /merchant-dashboard',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.go('/login');
        await tester.pumpAndSettle();

        expect(
          router.routeInformationProvider.value.uri.toString(),
          '/merchant-dashboard',
        );
      },
    );
  });

  group('Router Guard – Operator Deep Link Bypass Tests', () {
    late GoRouter router;

    setUp(() {
      router = AppRouter(operatorSession()).router;
    });

    tearDown(() {
      router.dispose();
    });

    testWidgets(
      'Operator navigating to /onboarding is redirected to /operator-dashboard',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.go('/onboarding');
        await tester.pumpAndSettle();

        expect(
          router.routeInformationProvider.value.uri.toString(),
          '/operator-dashboard',
        );
      },
    );

    testWidgets(
      'Operator navigating to /directory is redirected to /operator-dashboard',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.go('/directory');
        await tester.pumpAndSettle();

        expect(
          router.routeInformationProvider.value.uri.toString(),
          '/operator-dashboard',
        );
      },
    );
  });

  group('Session Role Resolution Tests', () {
    test('Guest session has correct role flags', () {
      final session = guestSession();
      expect(session.isGuest, isTrue);
      expect(session.isMerchant, isFalse);
      expect(session.isOperator, isFalse);
      expect(session.role, equals(UserRole.guest));
    });

    test('Merchant session has correct role flags', () {
      final session = merchantSession();
      expect(session.isGuest, isFalse);
      expect(session.isMerchant, isTrue);
      expect(session.isOperator, isFalse);
      expect(session.role, equals(UserRole.merchant));
    });

    test('Operator session has correct role flags', () {
      final session = operatorSession();
      expect(session.isGuest, isFalse);
      expect(session.isMerchant, isFalse);
      expect(session.isOperator, isTrue);
      expect(session.role, equals(UserRole.operator));
    });
  });
}
