import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_role.dart';

/// Immutable representation of the authenticated user's session state.
///
/// Constructed from a Supabase [User] object via [UserSession.fromSupabaseUser].
/// All role and permission data originates from `app_metadata` (server-controlled)
/// — never from `user_metadata` (client-writable).
class UserSession {
  final String? userId;
  final String? email;
  final String? displayName;
  final UserRole role;
  final VendorStatus vendorStatus;
  final bool isUaePassVerified;
  final User? rawUser;

  const UserSession({
    this.userId,
    this.email,
    this.displayName,
    required this.role,
    this.vendorStatus = VendorStatus.none,
    this.isUaePassVerified = false,
    this.rawUser,
  });

  // ─── Guest factory ──────────────────────────────────────────────────────────

  /// Returns an unauthenticated guest session with all fields empty.
  static const UserSession guest = UserSession(role: UserRole.guest);

  // ─── Supabase factory ───────────────────────────────────────────────────────

  /// Resolves a [UserSession] from the Supabase [User] JWT claims.
  ///
  /// Role resolution order (first match wins):
  /// 1. `app_metadata.role` — canonical field set by server-side functions
  /// 2. `app_metadata.user_role` — legacy field
  /// 3. Backward-compat mapping: `merchant → customer`, `operator → whAdmin`
  /// 4. Default fallback: `customer`
  factory UserSession.fromSupabaseUser(User? user) {
    if (user == null) return UserSession.guest;

    final appMeta = user.appMetadata;
    final userMeta = user.userMetadata ?? {};

    // ── Role resolution ──────────────────────────────────────────────────────
    final rawRole =
        (appMeta['role'] ?? appMeta['user_role'] ?? '').toString().toLowerCase();

    final UserRole role = switch (rawRole) {
      'super_admin' || 'superadmin'  => UserRole.superAdmin,
      'wh_admin' || 'whadmin' || 'admin' || 'operator' => UserRole.whAdmin,
      'vendor'                       => UserRole.vendor,
      'customer' || 'merchant'       => UserRole.customer,
      'guest'                        => UserRole.guest,
      _                              => UserRole.customer, // safe default for new signups
    };

    // ── Vendor status ────────────────────────────────────────────────────────
    final rawVendorStatus =
        (appMeta['vendor_status'] ?? '').toString().toLowerCase();

    final VendorStatus vendorStatus = switch (rawVendorStatus) {
      'approved'         => VendorStatus.approved,
      'pending_approval' => VendorStatus.pendingApproval,
      'rejected'         => VendorStatus.rejected,
      _                  => VendorStatus.none,
    };

    // ── UAE Pass verification ────────────────────────────────────────────────
    final bool isUaePassVerified =
        appMeta['is_uae_pass_verified'] == true ||
        appMeta['uae_pass_verified'] == true;

    // ── Display name ─────────────────────────────────────────────────────────
    final String displayName =
        userMeta['business_name']?.toString() ??
        userMeta['full_name']?.toString() ??
        userMeta['name']?.toString() ??
        user.email?.split('@').first ??
        'User';

    return UserSession(
      userId: user.id,
      email: user.email,
      displayName: displayName,
      role: role,
      vendorStatus: vendorStatus,
      isUaePassVerified: isUaePassVerified,
      rawUser: user,
    );
  }

  // ─── Permission helpers ─────────────────────────────────────────────────────

  bool get isGuest        => role == UserRole.guest;
  bool get isCustomer     => role == UserRole.customer;
  bool get isVendor       => role == UserRole.vendor;
  bool get isWhAdmin      => role == UserRole.whAdmin;
  bool get isSuperAdmin   => role == UserRole.superAdmin;

  /// True for any authenticated user (all non-guest roles).
  bool get isAuthenticated => role != UserRole.guest;

  /// Can rent shelves: requires UAE Pass verification (ROLE_CUSTOMER+).
  bool get canRentShelves => isUaePassVerified && isAuthenticated;

  /// Can list marketplace products: requires approved vendor status.
  bool get canListProducts =>
      (isVendor || isSuperAdmin) && vendorStatus == VendorStatus.approved;

  /// Can access warehouse admin operations.
  bool get canAccessWms => isWhAdmin || isSuperAdmin;

  /// Can approve/reject vendors and access financials.
  bool get canAccessSuperAdmin => isSuperAdmin;

  /// Vendor application is under review.
  bool get isVendorPending => vendorStatus == VendorStatus.pendingApproval;

  /// Vendor application was rejected — must re-apply.
  bool get isVendorRejected => vendorStatus == VendorStatus.rejected;

  @override
  String toString() =>
      'UserSession(role: $role, vendorStatus: $vendorStatus, '
      'uaePass: $isUaePassVerified, email: $email)';
}
