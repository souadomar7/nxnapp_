import 'package:isar/isar.dart';
import '../models/inventory_dto.dart';
import '../../../../core/storage/offline_transaction.dart';

class InventoryLocalSource {
  final Isar _isar;

  InventoryLocalSource(this._isar);

  /// Loads cached inventory items locally on the device database.
  Future<List<InventoryDto>> getCachedInventory() async {
    return await _isar.inventoryDtos.where().findAll();
  }

  /// Refreshes local Isar cache entries in a thread-safe write transaction block.
  Future<void> cacheInventory(List<InventoryDto> items) async {
    await _isar.writeTxn(() async {
      for (var item in items) {
        await _isar.inventoryDtos.putByIndex('inventoryId', item);
      }
    });
  }

  /// Appends transaction to database offline queue for later sync playback.
  Future<void> queueOfflineTransaction(OfflineTransaction txn) async {
    await _isar.writeTxn(() async {
      await _isar.offlineTransactions.put(txn);
    });
  }

  /// Loads all pending transaction records sorted by timestamp.
  Future<List<OfflineTransaction>> getPendingTransactions() async {
    return await _isar.offlineTransactions.where().sortByTimestamp().findAll();
  }

  /// Removes transaction from local queue after successful sync resolution.
  Future<void> removePendingTransaction(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.offlineTransactions.delete(id);
    });
  }

  /// Streams local Isar updates.
  Stream<List<InventoryDto>> watchCachedInventory() {
    return _isar.inventoryDtos.where().watch(fireImmediately: true);
  }
}
