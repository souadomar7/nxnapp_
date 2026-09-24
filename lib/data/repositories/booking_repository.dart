import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for warehouse booking and subscription operations.
class BookingRepository {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ── Warehouses ─────────────────────────────────────────────────────────────

  /// Returns all warehouses available on the platform.
  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final data = await _supabase.from('warehouses').select();
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Shelf Availability ─────────────────────────────────────────────────────

  /// Returns the number of available shelf slots in [warehouseId].
  /// Counts rows in `sme_inventory` that are unoccupied.
  Future<int> getAvailableShelves(String warehouseId) async {
    final data = await _supabase
        .from('sme_inventory')
        .select('id')
        .eq('warehouse_id', warehouseId)
        .eq('is_occupied', false);
    return (data as List).length;
  }

  // ── Booking / Subscription Creation ───────────────────────────────────────

  /// Creates a pending booking record in `sme_subscriptions`.
  /// The subscription is inactive until payment is confirmed server-side.
  ///
  /// Returns the new subscription's UUID.
  Future<String> createBookingRecord({
    required String warehouseId,
    required int shelvesCount,
    required int months,
    required String storageType,
    bool addWorkers = false,
    int workerCount = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final endDate = DateTime(now.year, now.month + months, now.day).toUtc();

    final data = await _supabase
        .from('sme_subscriptions')
        .insert({
          'seller_id': _uid,
          'warehouse_id': warehouseId,
          'shelves_count': shelvesCount,
          'months': months,
          'storage_type': storageType,
          'add_workers': addWorkers,
          'worker_count': workerCount,
          'is_active': false,
          'auto_renew': false,
          'cancellation_pending': false,
          'start_date': now.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'created_at': now.toIso8601String(),
        })
        .select('id')
        .single();

    return data['id'] as String;
  }

  // ── Active Subscriptions ───────────────────────────────────────────────────

  /// Returns all active subscriptions for the current user, ordered by end date.
  Future<List<Map<String, dynamic>>> getActiveSubscriptions() async {
    final data = await _supabase
        .from('sme_subscriptions')
        .select()
        .eq('seller_id', _uid)
        .eq('is_active', true)
        .order('end_date', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── All Subscriptions ─────────────────────────────────────────────────────

  /// Returns all subscriptions (active and inactive) for the current user.
  Future<List<Map<String, dynamic>>> getAllSubscriptions() async {
    final data = await _supabase
        .from('sme_subscriptions')
        .select()
        .eq('seller_id', _uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Cancel / Reactivate ───────────────────────────────────────────────────

  /// Marks subscription [subscriptionId] as pending cancellation.
  Future<void> cancelSubscription(
    String subscriptionId, {
    String? reason,
  }) async {
    await _supabase
        .from('sme_subscriptions')
        .update({
          'cancellation_pending': true,
          if (reason != null) 'cancellation_reason': reason,
        })
        .eq('id', subscriptionId)
        .eq('seller_id', _uid);
  }

  /// Clears the cancellation flag and re-enables auto-renewal.
  Future<void> reactivateSubscription(String subscriptionId) async {
    await _supabase
        .from('sme_subscriptions')
        .update({
          'cancellation_pending': false,
          'auto_renew': true,
        })
        .eq('id', subscriptionId)
        .eq('seller_id', _uid);
  }
}
