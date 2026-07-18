import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  /// Loads cached inventory items locally on the device database.
  Future<List<InventoryItem>> getInventoryLocal();

  /// Synchronizes stock adjustments to remote Supabase server using idempotency key protection.
  Future<void> syncInventoryRemote(List<InventoryItem> items, String idempotencyKey);

  /// Emits real-time streams of local inventory changes.
  Stream<List<InventoryItem>> watchInventory();
}
