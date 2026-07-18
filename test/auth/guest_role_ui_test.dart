import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nxnapp/core/auth/user_role.dart';
import 'package:nxnapp/core/auth/user_session.dart';
import 'package:nxnapp/core/auth/role_permission_shield.dart';

// ─── Mock stubs ───────────────────────────────────────────────────────────────

class FakeUserSession extends Fake implements UserSession {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

UserSession guestSession() => const UserSession(role: UserRole.guest);

/// Wraps a widget with Material so RolePermissionShield can render Scaffolds.
Widget buildTestApp(Widget child) {
  return MaterialApp(home: child);
}

/// Stub widgets that represent real guarded components.
class BarcodeWidget extends StatelessWidget {
  const BarcodeWidget({super.key});
  @override
  Widget build(BuildContext context) =>
      const Text('BARCODE_SCANNER_WIDGET', key: Key('barcode_scanner'));
}

class StripePaymentSheet extends StatelessWidget {
  const StripePaymentSheet({super.key});
  @override
  Widget build(BuildContext context) =>
      const Text('STRIPE_PAYMENT_SHEET', key: Key('stripe_payment_sheet'));
}

class AICopilotChat extends StatelessWidget {
  const AICopilotChat({super.key});
  @override
  Widget build(BuildContext context) =>
      const Text('AI_COPILOT_CHAT', key: Key('ai_copilot_chat'));
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserSession());
  });

  final UserSession guest = guestSession();

  group('Guest Role – UI Restriction Tests', () {
    testWidgets(
      'BarcodeWidget is NOT in the widget tree when user is a Guest',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            RolePermissionShield(
              allowedRoles: const [UserRole.merchant, UserRole.operator],
              currentUserRole: guest.role,
              showDeniedUI: false, // collapse entirely for guest
              child: const BarcodeWidget(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The scanner should NOT appear in the widget tree
        expect(find.byType(BarcodeWidget), findsNothing);
        expect(find.byKey(const Key('barcode_scanner')), findsNothing);
      },
    );

    testWidgets(
      'StripePaymentSheet is NOT in the widget tree when user is a Guest',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            RolePermissionShield(
              allowedRoles: const [UserRole.merchant],
              currentUserRole: guest.role,
              showDeniedUI: false,
              child: const StripePaymentSheet(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(StripePaymentSheet), findsNothing);
        expect(find.byKey(const Key('stripe_payment_sheet')), findsNothing);
      },
    );

    testWidgets(
      'AICopilotChat is NOT in the widget tree when user is a Guest',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            RolePermissionShield(
              allowedRoles: const [UserRole.merchant, UserRole.operator],
              currentUserRole: guest.role,
              showDeniedUI: false,
              child: const AICopilotChat(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AICopilotChat), findsNothing);
        expect(find.byKey(const Key('ai_copilot_chat')), findsNothing);
      },
    );

    testWidgets(
      'Shield shows a SizedBox.shrink (empty) widget when showDeniedUI is false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            RolePermissionShield(
              allowedRoles: const [UserRole.merchant],
              currentUserRole: guest.role,
              showDeniedUI: false,
              child: const BarcodeWidget(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The entire protected block collapses
        expect(find.byType(SizedBox), findsWidgets);
        expect(find.byType(BarcodeWidget), findsNothing);
      },
    );

    testWidgets(
      'Shield renders Access Denied view when showDeniedUI is true for Guests',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            RolePermissionShield(
              allowedRoles: const [UserRole.merchant],
              currentUserRole: guest.role,
              showDeniedUI: true,
              child: const BarcodeWidget(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The Access Denied scaffold should appear
        expect(find.text('Access Denied'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
        expect(find.text('Go Back'), findsOneWidget);
        // The protected child must NOT be visible
        expect(find.byType(BarcodeWidget), findsNothing);
      },
    );
  });
}
