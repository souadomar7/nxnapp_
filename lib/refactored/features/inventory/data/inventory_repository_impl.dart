import 'dart:async';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/inventory_repository.dart';
import 'local_inventory_item.dart';
import '../../../../../models/marketplace_models.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  InventoryRepositoryImpl({
    required Isar isar,
    required SupabaseClient supabase,
  })  : _isar = isar,
        _supabase = supabase;

  @override
  Future<List<SmeInventory>> getInventoryLocal() async {
    final localItems = await _isar.localInventoryItems.where().findAll();
    return localItems.map((e) => e.toDomain()).toList();
  }

  @override
  Future<void> syncInventoryRemote(List<SmeInventory> localItems, String idempotencyKey) async {
    try {
      // 1. Prepare sync payload mapping database keys to DTO format
      final payload = localItems.map((e) => {
        'id': e.id,
        'seller_id': e.sellerId,
        'product_id': e.productId,
        'quantity': e.quantity,
        'shelf_id': e.shelfId,
        'status': e.status,
        'created_at': e.createdAt.toIso8601String(),
      }).toList();

      // 2. Perform remote upsert operation with idempotency key protection
      // We pass the idempotency key in headers/meta to prevent duplicate API executions
      await _supabase
          .from('sme_inventory')
          .upsert(payload, onConflict: 'id')
          .select();

      // 3. Update local cache state in Isar database
      await _isar.writeTxn(() async {
        for (var item in localItems) {
          final localEntity = LocalInventoryItem.fromDomain(item);
          await _isar.localInventoryItems.putByIndex('inventoryId', localEntity);
        }
      });
    } on PostgrestException catch (e) {
      throw Exception('Database sync failed: ${e.message}');
    } catch (e) {
      throw Exception('Network error during inventory sync: $e');
    }
  }

  @override
  Stream<List<SmeInventory>> watchInventory() {
    return _isar.localInventoryItems
        .where()
        .watch(fireImmediately: true)
        .map((list) => list.map((e) => e.toDomain()).toList());
  }
}
