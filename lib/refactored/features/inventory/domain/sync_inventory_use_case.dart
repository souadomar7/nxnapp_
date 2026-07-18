import 'inventory_repository.dart';
import '../../../../../models/marketplace_models.dart';

class SyncInventoryUseCase {
  final InventoryRepository _repository;

  SyncInventoryUseCase(this._repository);

  /// Executes the synchronization of local stock adjustments with the remote database.
  /// Accepts an idempotency key to protect against duplicate sync updates.
  Future<void> call(List<SmeInventory> localItems, String idempotencyKey) async {
    if (localItems.isEmpty) return;
    await _repository.syncInventoryRemote(localItems, idempotencyKey);
  }
}
