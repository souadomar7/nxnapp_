import '../entities/inventory_item.dart';
import '../repositories/inventory_repository.dart';

class SyncInventoryUseCase {
  final InventoryRepository _repository;

  SyncInventoryUseCase(this._repository);

  /// Triggers the cloud-synchronization pipeline for inventory, utilizing idempotency keys.
  Future<void> call(List<InventoryItem> items, String idempotencyKey) async {
    if (items.isEmpty) return;
    await _repository.syncInventoryRemote(items, idempotencyKey);
  }
}
