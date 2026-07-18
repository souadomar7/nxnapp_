import 'package:isar/isar.dart';
import 'offline_transaction.dart';

class LocalQueueRepository {
  final Isar _isar;

  LocalQueueRepository(this._isar);

  /// Queues a transaction safely within a write transaction.
  /// This ensures sequential consistency and database-level thread safety.
  Future<void> queueTransaction(OfflineTransaction txn) async {
    await _isar.writeTxn(() async {
      await _isar.offlineTransactions.put(txn);
    });
  }

  /// Retrieves all pending queued transactions sorted chronologically.
  Future<List<OfflineTransaction>> getAllPending() async {
    return await _isar.offlineTransactions
        .where()
        .sortByTimestamp()
        .findAll();
  }

  /// Removes a transaction from the queue by its ID after successful remote sync.
  Future<void> removeTransaction(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.offlineTransactions.delete(id);
    });
  }

  /// Clears the entire queue.
  Future<void> clearQueue() async {
    await _isar.writeTxn(() async {
      await _isar.offlineTransactions.clear();
    });
  }
}
