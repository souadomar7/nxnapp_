import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/offline_gate_pass.dart';

class GatePassSyncService {
  static const String _boxName = 'nxn_offline_gate_passes';
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _isSyncing = false;

  /// ValueNotifier to inform the UI of pending unsynced passes count
  static final ValueNotifier<int> pendingSyncCount = ValueNotifier<int>(0);

  /// Initialize Hive box and start listening to connectivity events
  static Future<void> initialize() async {
    await Hive.openBox<String>(_boxName);
    _updatePendingCount();

    // Start listening to connectivity state transitions
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final bool hasConnection = results.any((result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);

      if (hasConnection) {
        debugPrint('[NXN Sync Engine] Network restored. Flushing queue...');
        await flushQueue();
      }
    });

    // Check immediate network status on app start
    final initialResults = await Connectivity().checkConnectivity();
    if (initialResults.any((r) => r != ConnectivityResult.none)) {
      await flushQueue();
    }
  }

  static Box<String> get _box => Hive.box<String>(_boxName);

  /// Queue a new pass offline
  static Future<void> enqueuePass(OfflineGatePass pass) async {
    await _box.put(pass.passCode, pass.toJson());
    _updatePendingCount();

    // Attempt immediate push if online
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.any((r) => r != ConnectivityResult.none)) {
      await flushQueue();
    }
  }

  /// Synchronize all pending items to Supabase
  static Future<void> flushQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    final client = Supabase.instance.client;

    // Check auth session before executing
    if (client.auth.currentUser == null) {
      debugPrint('[NXN Sync Engine] User unauthenticated. Postponing sync.');
      _isSyncing = false;
      return;
    }

    try {
      final rawEntries = _box.toMap();

      for (final entry in rawEntries.entries) {
        final pass = OfflineGatePass.fromJson(entry.value);

        if (pass.syncStatus == SyncStatus.pending || pass.syncStatus == SyncStatus.failed) {
          try {
            // Idempotent upsert via PostgREST RPC
            final response = await client.rpc('sync_offline_gate_pass', params: {
              'p_pass_code': pass.passCode,
              'p_lease_id': pass.leaseId,
              'p_qr_signature': pass.qrSignature,
              'p_dock_gate': pass.dockGate,
              'p_driver_name': pass.driverName,
              'p_driver_license': pass.driverLicense,
              'p_vehicle_plate': pass.vehiclePlate,
              'p_valid_until': pass.validUntilIso,
              'p_idempotency_key': pass.idempotencyKey,
            });

            if (response != null && response['success'] == true) {
              pass.syncStatus = SyncStatus.synced;
              await _box.put(pass.passCode, pass.toJson());
              debugPrint('[NXN Sync Engine] Successfully synced pass: ${pass.passCode}');
            } else {
              pass.retryCount += 1;
              if (pass.retryCount > 5) pass.syncStatus = SyncStatus.failed;
              await _box.put(pass.passCode, pass.toJson());
            }
          } catch (e) {
            debugPrint('[NXN Sync Engine] Sync error for ${pass.passCode}: $e');
            pass.retryCount += 1;
            await _box.put(pass.passCode, pass.toJson());
          }
        }
      }
    } finally {
      _updatePendingCount();
      _isSyncing = false;
    }
  }

  static void _updatePendingCount() {
    int count = 0;
    for (final raw in _box.values) {
      final pass = OfflineGatePass.fromJson(raw);
      if (pass.syncStatus == SyncStatus.pending) {
        count++;
      }
    }
    pendingSyncCount.value = count;
  }

  static Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
  }
}
