import 'dart:convert';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_local_source.dart';
import '../datasources/inventory_remote_source.dart';
import '../models/inventory_dto.dart';
import '../../../../core/storage/offline_transaction.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalSource _localSource;
  final InventoryRemoteSource _remoteSource;

  InventoryRepositoryImpl({
    required InventoryLocalSource localSource,
    required InventoryRemoteSource remoteSource,
  })  : _localSource = localSource,
        _remoteSource = remoteSource;

  @override
  Future<List<InventoryItem>> getInventoryLocal() async {
    final dtos = await _localSource.getCachedInventory();
    return dtos.map((e) => e.toDomain()).toList();
  }

  @override
  Future<void> syncInventoryRemote(List<InventoryItem> items, String idempotencyKey) async {
    final dtos = items.map((e) => InventoryDto.fromDomain(e)).toList();
    
    try {
      // 1. Execute direct remote sync
      await _remoteSource.upsertRemoteInventory(dtos, idempotencyKey);
      
      // 2. Refresh local database cache
      await _localSource.cacheInventory(dtos);

      // 3. Playback queue on connection recovery
      await processPendingSyncs();
    } catch (e) {
      // 4. Save transaction log on disconnect to replay later
      final pendingTxn = OfflineTransaction()
        ..idempotencyKey = idempotencyKey
        ..actionType = 'SYNC_INVENTORY'
        ..payloadJson = jsonEncode(dtos.map((e) => e.toJson()).toList())
        ..timestamp = DateTime.now();

      await _localSource.queueOfflineTransaction(pendingTxn);
      throw Exception('Network drop detected. Sync queued locally: $e');
    }
  }

  /// Processes queued offline changes sequentially.
  Future<void> processPendingSyncs() async {
    final pending = await _localSource.getPendingTransactions();
    if (pending.isEmpty) return;

    for (var txn in pending) {
      try {
        if (txn.actionType == 'SYNC_INVENTORY') {
          final List<dynamic> decoded = jsonDecode(txn.payloadJson);
          final dtos = decoded.map((json) => InventoryDto.fromJson(json)).toList();
          await _remoteSource.upsertRemoteInventory(dtos, txn.idempotencyKey);
          await _localSource.removePendingTransaction(txn.id);
        }
      } catch (e) {
        break; // Retry later if connections drop again
      }
    }
  }

  @override
  Stream<List<InventoryItem>> watchInventory() {
    return _localSource.watchCachedInventory()
        .map((list) => list.map((e) => e.toDomain()).toList());
  }
}
