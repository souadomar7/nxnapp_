import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nxnapp/core/auth/user_role.dart';
import 'package:nxnapp/core/auth/user_session.dart';
import 'package:nxnapp/core/auth/role_permission_shield.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

UserSession merchantSession() => const UserSession(role: UserRole.merchant);

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
  final UserSession merchant = merchantSession();

  group('Merchant Role – UI Visibility Tests', () {
    testWidgets(
      'Seller Hub Dashboard renders all sections when user is a Merchant',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            RolePermissionShield(
              allowedRoles: const [UserRole.merchant],
              currentUserRole: merchant.role,
              child: const SellerHubDashboard(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // All seller hub sections must render
        expect(find.byKey(const Key('seller_hub_dashboard')), findsOneWidget);
        expect(find.byKey(const Key('seller_hub_inventory')), findsOneWidget);
        expect(find.byKey(const Key('seller_hub_bookings')), findsOneWidget);
        // Access Denied view must NOT appear
        expect(find.text('Access Denied'), findsNothing);
      },
    );

    testWidgets(
      'WMS Operator Scanner is completely absent from widget tree for Merchant',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            RolePermissionShield(
              allowedRoles: const [UserRole.operator],
              currentUserRole: merchant.role,
              showDeniedUI: false,
              child: const WMSScannerView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scanner must not be present
        expect(find.byType(WMSScannerView), findsNothing);
        expect(find.byKey(const Key('wms_operator_scanner')), findsNothing);
      },
    );

    testWidgets(
      'WMS Operator Scanner shows Permission Denied view for Merchant',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            RolePermissionShield(
              allowedRoles: const [UserRole.operator],
              currentUserRole: merchant.role,
              showDeniedUI: true,
              child: const WMSScannerView(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Permission Denied scaffold should render
        expect(find.text('Access Denied'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
        // The actual WMS scanner content must be hidden
        expect(find.byType(WMSScannerView), findsNothing);
        expect(find.byKey(const Key('wms_operator_scanner')), findsNothing);
      },
    );

    testWidgets(
      'Merchant role is correctly identified from UserSession',
      (WidgetTester tester) async {
        expect(merchant.isMerchant, isTrue);
        expect(merchant.isOperator, isFalse);
        expect(merchant.isGuest, isFalse);
      },
    );
  });
}
