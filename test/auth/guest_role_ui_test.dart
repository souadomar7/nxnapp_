import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nxnapp/core/auth/user_role.dart';
import 'package:nxnapp/core/auth/user_session.dart';
import 'package:nxnapp/core/auth/session_provider.dart';

// ─── Mock stubs ───────────────────────────────────────────────────────────────

class FakeUserSession extends Fake implements UserSession {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

UserSession guestSession() => UserSession.guest;

/// Wraps a widget with Material so RoleViewGuard can render.
Widget buildTestApp(Widget child) {
  return MaterialApp(home: child);
}

// ─── Stub widgets ─────────────────────────────────────────────────────────────

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
            SessionProvider(
              session: guest,
              child: RoleViewGuard(
                allowedRoles: const [UserRole.customer, UserRole.whAdmin],
                showLockedUI: false, // collapse entirely for guest
                child: const BarcodeWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BarcodeWidget), findsNothing);
        expect(find.byKey(const Key('barcode_scanner')), findsNothing);
      },
    );

    testWidgets(
      'StripePaymentSheet is NOT in the widget tree when user is a Guest',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SessionProvider(
              session: guest,
              child: RoleViewGuard(
                allowedRoles: const [UserRole.customer],
                showLockedUI: false,
                child: const StripePaymentSheet(),
              ),
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
            SessionProvider(
              session: guest,
              child: RoleViewGuard(
                allowedRoles: const [UserRole.customer, UserRole.vendor],
                showLockedUI: false,
                child: const AICopilotChat(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AICopilotChat), findsNothing);
        expect(find.byKey(const Key('ai_copilot_chat')), findsNothing);
      },
    );

    testWidgets(
      'Shield shows a SizedBox.shrink (empty) widget when showLockedUI is false',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SessionProvider(
              session: guest,
              child: RoleViewGuard(
                allowedRoles: const [UserRole.customer],
                showLockedUI: false,
                child: const BarcodeWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SizedBox), findsWidgets);
        expect(find.byType(BarcodeWidget), findsNothing);
      },
    );

    testWidgets(
      'Shield renders locked placeholder when showLockedUI is true for Guests',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SessionProvider(
              session: guest,
              child: RoleViewGuard(
                allowedRoles: const [UserRole.customer],
                showLockedUI: true,
                child: const BarcodeWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sign Up to Unlock'), findsOneWidget);
        expect(find.text('Sign Up Free'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      },
    );
  });
}
