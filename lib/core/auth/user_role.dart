/// PRD §2 — User Role Definitions
///
/// Roles are resolved from Supabase `app_metadata.role` at login time.
/// The [UserSession] factory handles backward-compatible mapping for
/// existing users who have `merchant` or `operator` stored in the DB.
enum UserRole {
  /// Unauthenticated. Read-only marketplace and warehouse info access.
  guest,

  /// Email/Phone verified + UAE Pass OIDC verified renter.
  /// Can rent shelves, request delivery, view personal inventory.
  customer,

  /// [customer] + Trade License approved by Super Admin.
  /// Can list and manage products on the marketplace.
  vendor,

  /// Logistics Courier / Field Driver.
  /// Can view assigned deliveries, capture PoD, and verify gate passes.
  driver,

  /// Warehouse Operations Staff (internal credentials).
  /// Can update stock, conduct intake, upload damage photos, manage workers.
  whAdmin,

  /// Platform Executive (MFA internal credentials).
  /// Full system administration, vendor license approvals, financial analytics.
  superAdmin,
}

/// Vendor upgrade progression states, stored in Supabase `app_metadata.vendor_status`.
enum VendorStatus {
  /// Default — user has not applied for vendor access.
  none,

  /// Trade license submitted, awaiting Super Admin review.
  pendingApproval,

  /// Trade license approved. Full marketplace listing access granted.
  approved,

  /// Trade license rejected. User must re-submit with corrected documents.
  rejected,
}
