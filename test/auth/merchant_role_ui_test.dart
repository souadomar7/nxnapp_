import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nxnapp/core/auth/user_role.dart';
import 'package:nxnapp/core/auth/user_session.dart';
import 'package:nxnapp/core/auth/session_provider.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

UserSession customerSession() => const UserSession(role: UserRole.customer);

Widget buildTestApp(Widget child) {
  return MaterialApp(home: child);
}

// ─── Stub Widgets ─────────────────────────────────────────────────────────────

class SellerHubDashboard extends StatelessWidget {
  const SellerHubDashboard({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: const [
            Text('Seller Hub Dashboard', key: Key('seller_hub_dashboard')),
            Text('My Inventory', key: Key('seller_hub_inventory')),
            Text('Booking History', key: Key('seller_hub_bookings')),
          ],
        ),
      );
}

class WMSScannerView extends StatelessWidget {
  const WMSScannerView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Text('WMS_OPERATOR_SCANNER', key: Key('wms_operator_scanner'));
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  final UserSession customer = customerSession();

  group('Customer Role – UI Visibility Tests', () {
    testWidgets(
      'Seller Hub Dashboard renders all sections when user is a Customer',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SessionProvider(
              session: customer,
              child: RoleViewGuard(
                allowedRoles: const [UserRole.customer],
                child: const SellerHubDashboard(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('seller_hub_dashboard')), findsOneWidget);
        expect(find.byKey(const Key('seller_hub_inventory')), findsOneWidget);
        expect(find.byKey(const Key('seller_hub_bookings')), findsOneWidget);
        expect(find.text('Sign Up to Unlock'), findsNothing);
      },
    );

    testWidgets(
      'WMS Operator Scanner is completely absent from widget tree for Customer',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SessionProvider(
              session: customer,
              child: RoleViewGuard(
                allowedRoles: const [UserRole.whAdmin],
                showLockedUI: false,
                child: const WMSScannerView(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WMSScannerView), findsNothing);
        expect(find.byKey(const Key('wms_operator_scanner')), findsNothing);
      },
    );

    testWidgets(
      'WMS Operator Scanner shows Locked UI view for Customer',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            SessionProvider(
              session: customer,
              child: RoleViewGuard(
                allowedRoles: const [UserRole.whAdmin],
                showLockedUI: true,
                child: const WMSScannerView(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sign Up to Unlock'), findsOneWidget);
      },
    );

    testWidgets(
      'Customer role is correctly identified from UserSession',
      (WidgetTester tester) async {
        expect(customer.isCustomer, isTrue);
        expect(customer.isWhAdmin, isFalse);
        expect(customer.isGuest, isFalse);
      },
    );
  });
}
