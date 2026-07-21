import 'package:flutter_test/flutter_test.dart';
import 'package:nxnapp/core/auth/user_role.dart';
import 'package:nxnapp/core/auth/user_session.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

UserSession guestSession() => UserSession.guest;
UserSession customerSession() => const UserSession(role: UserRole.customer);
UserSession vendorSession() => const UserSession(role: UserRole.vendor, vendorStatus: VendorStatus.approved);
UserSession whAdminSession() => const UserSession(role: UserRole.whAdmin);
UserSession superAdminSession() => const UserSession(role: UserRole.superAdmin);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('Session Role Resolution Tests', () {
    test('Guest session has correct role flags', () {
      final session = guestSession();
      expect(session.isGuest, isTrue);
      expect(session.isCustomer, isFalse);
      expect(session.isVendor, isFalse);
      expect(session.isWhAdmin, isFalse);
      expect(session.isSuperAdmin, isFalse);
      expect(session.role, equals(UserRole.guest));
      expect(session.canRentShelves, isFalse);
      expect(session.canListProducts, isFalse);
      expect(session.canAccessWms, isFalse);
    });

    test('Customer session has correct role flags', () {
      final session = customerSession();
      expect(session.isGuest, isFalse);
      expect(session.isCustomer, isTrue);
      expect(session.isVendor, isFalse);
      expect(session.role, equals(UserRole.customer));
      expect(session.canAccessWms, isFalse);
    });

    test('Vendor session has correct role flags', () {
      final session = vendorSession();
      expect(session.isGuest, isFalse);
      expect(session.isVendor, isTrue);
      expect(session.canListProducts, isTrue);
      expect(session.role, equals(UserRole.vendor));
    });

    test('Warehouse Admin session has correct role flags', () {
      final session = whAdminSession();
      expect(session.isGuest, isFalse);
      expect(session.isWhAdmin, isTrue);
      expect(session.canAccessWms, isTrue);
      expect(session.canAccessSuperAdmin, isFalse);
      expect(session.role, equals(UserRole.whAdmin));
    });

    test('Super Admin session has correct role flags', () {
      final session = superAdminSession();
      expect(session.isGuest, isFalse);
      expect(session.isSuperAdmin, isTrue);
      expect(session.canAccessWms, isTrue);
      expect(session.canAccessSuperAdmin, isTrue);
      expect(session.role, equals(UserRole.superAdmin));
    });
  });
}
