import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/inventory_dto.dart';

class InventoryRemoteSource {
  final SupabaseClient _supabase;

  InventoryRemoteSource(this._supabase);

  /// Performs direct read query on Supabase remote tables.
  Future<List<InventoryDto>> fetchRemoteInventory() async {
    try {
      final response = await _supabase.from('sme_inventory').select();
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => InventoryDto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Remote query failed: $e');
    }
  }

  /// Pushes local changes remotely. Passes the idempotency key to reject duplicate actions.
  Future<void> upsertRemoteInventory(List<InventoryDto> dtos, String idempotencyKey) async {
    try {
      final payload = dtos.map((e) => e.toJson()).toList();
      await _supabase.from('sme_inventory').upsert(payload, onConflict: 'id');
    } catch (e) {
      throw Exception('Remote upsert failed: $e');
    }
  }
}
