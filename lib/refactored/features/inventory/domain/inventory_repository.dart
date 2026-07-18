import '../../../../../models/marketplace_models.dart';

abstract class InventoryRepository {
  /// Fetches inventory cached locally in the database.
  Future<List<SmeInventory>> getInventoryLocal();

  /// Synchronizes local modifications to remote Supabase database using idempotency keys.
  Future<void> syncInventoryRemote(List<SmeInventory> localItems, String idempotencyKey);

  /// Streams real-time updates of the inventory collection.
  Stream<List<SmeInventory>> watchInventory();
}
