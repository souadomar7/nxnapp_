import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/history_models.dart';
import '../models/invoice.dart';
import '../services/marketplace_service.dart';

/// Summary of an active warehouse lease for the merchant.
class WarehouseLeaseSummary {
  final String warehouseId;
  final String warehouseName;
  final String warehouseNameAr;
  final int shelvesCount;
  final double occupancyPercent;
  final double pricePerShelf;
  final bool isActive;

  const WarehouseLeaseSummary({
    required this.warehouseId,
    required this.warehouseName,
    required this.warehouseNameAr,
    required this.shelvesCount,
    required this.occupancyPercent,
    required this.pricePerShelf,
    this.isActive = true,
  });

  String displayName(bool isAr) {
    final meta = MerchantDataProvider._resolveWarehouseMeta(
      id: warehouseId,
      name: warehouseName,
      nameAr: warehouseNameAr,
    );
    return isAr ? meta.nameAr : meta.nameEn;
  }

  Map<String, dynamic> toJson() => {
    'warehouse_id': warehouseId,
    'warehouse_name': warehouseName,
    'warehouse_name_ar': warehouseNameAr,
    'shelves_count': shelvesCount,
    'occupancy_percent': occupancyPercent,
    'price_per_shelf': pricePerShelf,
    'is_active': isActive,
  };

  factory WarehouseLeaseSummary.fromJson(Map<String, dynamic> json) {
    return WarehouseLeaseSummary(
      warehouseId: json['warehouse_id'] ?? '',
      warehouseName: json['warehouse_name'] ?? 'Warehouse Hub',
      warehouseNameAr: json['warehouse_name_ar'] ?? '',
      shelvesCount: (json['shelves_count'] as num?)?.toInt() ?? 0,
      occupancyPercent: (json['occupancy_percent'] as num?)?.toDouble() ?? 0.75,
      pricePerShelf: (json['price_per_shelf'] as num?)?.toDouble() ?? 100.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

/// Centralized Single-Source-of-Truth Provider for Merchant Dashboard & Operations.
class MerchantDataProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MarketplaceService _marketplaceService = MarketplaceService();

  static const String _cacheKey = 'nxn_merchant_dashboard_snapshot';

  // --- Reactive State Variables ---
  int _totalShelves = 0;
  int _activeHubsCount = 0;
  List<WarehouseLeaseSummary> _activeSubscriptions = [];

  double _totalStockValue = 0.0;
  int _pendingOrdersCount = 0;
  double _walletBalance = 0.0; // Clean fresh app state

  List<DashboardActivity> _recentActivities = [];
  int _pendingInvoicesCount = 0;
  double _pendingInvoicesTotal = 0.0;

  bool _isLoading = true;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;

  RealtimeChannel? _realtimeChannel;
  Timer? _debounceTimer;

  // --- Getters ---
  int get totalShelves => _totalShelves;
  int get activeHubsCount => _activeHubsCount;
  List<WarehouseLeaseSummary> get activeSubscriptions => List.unmodifiable(_activeSubscriptions);

  double get totalStockValue => _totalStockValue;
  String get formattedStockValue {
    if (_totalStockValue >= 1000) {
      return '${(_totalStockValue / 1000).toStringAsFixed(1)}k';
    }
    return _totalStockValue.toStringAsFixed(0);
  }

  int get pendingOrdersCount => _pendingOrdersCount;

  double get walletBalance => _walletBalance;
  String get formattedWalletBalance => _walletBalance.toStringAsFixed(2);

  List<DashboardActivity> get recentActivities => List.unmodifiable(_recentActivities);
  int get pendingInvoicesCount => _pendingInvoicesCount;
  double get pendingInvoicesTotal => _pendingInvoicesTotal;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  // ════════════════════════════════════════════════════════════════════════════
  // INITIALIZATION & CACHE HYDRATION
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    // 1. Instant hydration from local storage (Zero UI shift / no skeletons)
    await _hydrateFromLocalCache();

    // 2. Set up Supabase Realtime Event Bus
    _setupRealtimeSubscriptions();

    // 3. Listen to MarketplaceService local updates
    MarketplaceService.updateNotifier.addListener(_onMarketplaceServiceUpdated);

    // 4. Remote background sync
    await refreshDashboard(force: true);
  }

  void _onMarketplaceServiceUpdated() {
    _debounceSync();
  }

  Future<void> _hydrateFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJsonStr = prefs.getString(_cacheKey);
      if (cachedJsonStr != null) {
        final Map<String, dynamic> data = jsonDecode(cachedJsonStr);
        _totalShelves = (data['total_shelves'] as num?)?.toInt() ?? 0;
        _activeHubsCount = (data['active_hubs_count'] as num?)?.toInt() ?? 0;
        _totalStockValue = (data['total_stock_value'] as num?)?.toDouble() ?? 0.0;
        _pendingOrdersCount = (data['pending_orders_count'] as num?)?.toInt() ?? 0;
        _walletBalance = (data['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        _pendingInvoicesCount = (data['pending_invoices_count'] as num?)?.toInt() ?? 0;
        _pendingInvoicesTotal = (data['pending_invoices_total'] as num?)?.toDouble() ?? 0.0;

        if (data['active_subscriptions'] is List) {
          _activeSubscriptions = (data['active_subscriptions'] as List)
              .map((e) => WarehouseLeaseSummary.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[MerchantDataProvider] Error hydrating from cache: $e');
    }
  }

  Future<void> _persistToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = {
        'total_shelves': _totalShelves,
        'active_hubs_count': _activeHubsCount,
        'total_stock_value': _totalStockValue,
        'pending_orders_count': _pendingOrdersCount,
        'wallet_balance': _walletBalance,
        'pending_invoices_count': _pendingInvoicesCount,
        'pending_invoices_total': _pendingInvoicesTotal,
        'active_subscriptions': _activeSubscriptions.map((e) => e.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_cacheKey, jsonEncode(snapshot));
    } catch (e) {
      debugPrint('[MerchantDataProvider] Error persisting cache: $e');
    }
  }

  Future<void> clearAllData() async {
    _totalShelves = 0;
    _activeHubsCount = 0;
    _activeSubscriptions = [];
    _totalStockValue = 0.0;
    _pendingOrdersCount = 0;
    _walletBalance = 0.0;
    _recentActivities = [];
    _pendingInvoicesCount = 0;
    _pendingInvoicesTotal = 0.0;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // REAL-TIME EVENT BUS (Supabase Realtime)
  // ════════════════════════════════════════════════════════════════════════════

  void _setupRealtimeSubscriptions() {
    try {
      _realtimeChannel = _supabase.channel('merchant_dashboard_realtime')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sme_orders',
          callback: (payload) {
            debugPrint('[MerchantDataProvider] Realtime event on sme_orders: ${payload.eventType}');
            _debounceSync();
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sme_products',
          callback: (payload) {
            debugPrint('[MerchantDataProvider] Realtime event on sme_products: ${payload.eventType}');
            _debounceSync();
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sme_subscriptions',
          callback: (payload) {
            debugPrint('[MerchantDataProvider] Realtime event on sme_subscriptions: ${payload.eventType}');
            _debounceSync();
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dashboard_activities',
          callback: (payload) {
            debugPrint('[MerchantDataProvider] Realtime event on dashboard_activities: ${payload.eventType}');
            _debounceSync();
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'wallets',
          callback: (payload) {
            debugPrint('[MerchantDataProvider] Realtime event on wallets: ${payload.eventType}');
            _debounceSync();
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payout_requests',
          callback: (payload) {
            debugPrint('[MerchantDataProvider] Realtime event on payout_requests: ${payload.eventType}');
            _debounceSync();
          },
        )
        ..subscribe();
    } catch (e) {
      debugPrint('[MerchantDataProvider] Realtime subscription init error: $e');
    }
  }

  void _debounceSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      refreshDashboard();
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SYNCHRONIZATION ENGINE
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> refreshDashboard({bool force = false}) async {
    if (_isSyncing && !force) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      final sellerId = user?.id;

      // 1. Fetch Subscriptions & Active Shelves
      await _syncSubscriptions(sellerId);

      // 2. Fetch Products & Calculate Stock Value
      await _syncProductsAndStockValue(sellerId);

      // 3. Fetch Orders & Calculate Dispatch / Wallet Balance
      await _syncOrdersAndWallet(sellerId);

      // 4. Fetch Activities & Invoices
      await _syncRecentActivities(sellerId);

      _lastSyncedAt = DateTime.now();
      await _persistToLocalCache();
    } catch (e) {
      debugPrint('[MerchantDataProvider] Refresh error (falling back to local): $e');
    } finally {
      _isLoading = false;
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ─── Warehouse Name & Metadata Resolver Helper ────────────────────────────
  static ({String canonicalId, String nameEn, String nameAr, double price}) _resolveWarehouseMeta({
    String? id,
    String? name,
    String? nameAr,
    double? price,
  }) {
    final rawId = (id ?? '').toLowerCase().trim();
    final rawName = (name ?? '').toLowerCase().trim();
    final rawNameAr = (nameAr ?? '').trim();

    if (rawId == 'auh' ||
        rawId == 'wh-auh' ||
        rawId.contains('auh') ||
        rawId.contains('abu') ||
        rawName.contains('abu dhabi') ||
        rawName.contains('auh') ||
        rawName.contains('أبوظبي') ||
        rawName.contains('أبو ظبي') ||
        rawNameAr.contains('أبوظبي') ||
        rawNameAr.contains('أبو ظبي')) {
      return (
        canonicalId: 'auh',
        nameEn: 'Abu Dhabi Central Hub',
        nameAr: 'مستودع أبوظبي المركزي',
        price: price ?? 100.0,
      );
    }
    if (rawId == 'shj' ||
        rawId == 'wh-shj' ||
        rawId.contains('shj') ||
        rawId.contains('sharjah') ||
        rawName.contains('sharjah') ||
        rawName.contains('الشارقة') ||
        rawNameAr.contains('الشارقة')) {
      return (
        canonicalId: 'shj',
        nameEn: 'Sharjah Regional Hub',
        nameAr: 'مستودع الشارقة الإقليمي',
        price: price ?? 100.0,
      );
    }
    if (rawId == 'aln' ||
        rawId == 'wh-aln' ||
        rawId.contains('aln') ||
        rawId.contains('ain') ||
        rawName.contains('al ain') ||
        rawName.contains('العين') ||
        rawNameAr.contains('العين')) {
      return (
        canonicalId: 'aln',
        nameEn: 'Al Ain Regional Hub',
        nameAr: 'مستودع العين الإقليمي',
        price: price ?? 100.0,
      );
    }

    // Default to Dubai Central Hub
    return (
      canonicalId: 'dxb',
      nameEn: 'Dubai Central Hub',
      nameAr: 'مستودع دبي المركزي',
      price: price ?? 100.0,
    );
  }

  // ─── 1. Subscriptions & Shelves ──────────────────────────────────────────
  Future<void> _syncSubscriptions(String? sellerId) async {
    final Map<String, WarehouseLeaseSummary> leasesMap = {};

    if (sellerId != null) {
      try {
        final subsData = await _supabase
            .from('sme_subscriptions')
            .select('*, warehouses(id, name, name_ar, total_shelves, price_per_shelf)')
            .eq('seller_id', sellerId)
            .eq('is_active', true);

        for (var sub in (subsData as List)) {
          final wh = sub['warehouses'] as Map<String, dynamic>? ?? {};
          final rawId = sub['warehouse_id']?.toString() ?? wh['id']?.toString() ?? 'wh-dxb';
          final meta = _resolveWarehouseMeta(
            id: rawId,
            name: wh['name']?.toString(),
            nameAr: wh['name_ar']?.toString(),
            price: (wh['price_per_shelf'] as num?)?.toDouble(),
          );
          final key = meta.canonicalId;
          final shelves = (sub['shelves_count'] as num?)?.toInt() ?? 0;

          if (leasesMap.containsKey(key)) {
            final existing = leasesMap[key]!;
            leasesMap[key] = WarehouseLeaseSummary(
              warehouseId: key,
              warehouseName: meta.nameEn,
              warehouseNameAr: meta.nameAr,
              shelvesCount: existing.shelvesCount + shelves,
              occupancyPercent: 0.85,
              pricePerShelf: meta.price,
            );
          } else {
            leasesMap[key] = WarehouseLeaseSummary(
              warehouseId: key,
              warehouseName: meta.nameEn,
              warehouseNameAr: meta.nameAr,
              shelvesCount: shelves,
              occupancyPercent: 0.85,
              pricePerShelf: meta.price,
            );
          }
        }
      } catch (e) {
        debugPrint('[MerchantDataProvider] Error querying sme_subscriptions: $e');
      }
    }

    // Only hydrate from local invoices if remote returned nothing (guest/offline mode)
    if (leasesMap.isEmpty) {
      try {
        final invoices = await _marketplaceService.getInvoices();
        for (final inv in invoices) {
          if (inv.type == InvoiceType.rental && inv.paid) {
            final metaData = inv.metaData ?? {};
            if (metaData.containsKey('warehouseIds')) {
              final List<dynamic> wIds = metaData['warehouseIds'] as List<dynamic>? ?? [];
              for (final wId in wIds) {
                final idStr = wId.toString();
                final shelves = (metaData['shelves_$idStr'] as num?)?.toInt() ?? 5;
                final resolved = _resolveWarehouseMeta(id: idStr);
                final key = resolved.canonicalId;

                if (leasesMap.containsKey(key)) {
                  final existing = leasesMap[key]!;
                  leasesMap[key] = WarehouseLeaseSummary(
                    warehouseId: key,
                    warehouseName: resolved.nameEn,
                    warehouseNameAr: resolved.nameAr,
                    shelvesCount: existing.shelvesCount + shelves,
                    occupancyPercent: 0.85,
                    pricePerShelf: resolved.price,
                  );
                } else {
                  leasesMap[key] = WarehouseLeaseSummary(
                    warehouseId: key,
                    warehouseName: resolved.nameEn,
                    warehouseNameAr: resolved.nameAr,
                    shelvesCount: shelves,
                    occupancyPercent: 0.85,
                    pricePerShelf: resolved.price,
                  );
                }
              }
            } else {
              final primaryId = metaData['primaryWarehouseId']?.toString() ?? inv.warehouseName;
              final shelves = (metaData['shelves'] as num?)?.toInt() ?? 5;
              final resolved = _resolveWarehouseMeta(
                id: primaryId,
                name: inv.warehouseName,
                nameAr: inv.warehouseNameAr,
              );
              final key = resolved.canonicalId;
              if (leasesMap.containsKey(key)) {
                final existing = leasesMap[key]!;
                leasesMap[key] = WarehouseLeaseSummary(
                  warehouseId: key,
                  warehouseName: resolved.nameEn,
                  warehouseNameAr: resolved.nameAr,
                  shelvesCount: existing.shelvesCount + shelves,
                  occupancyPercent: 0.85,
                  pricePerShelf: resolved.price,
                );
              } else {
                leasesMap[key] = WarehouseLeaseSummary(
                  warehouseId: key,
                  warehouseName: resolved.nameEn,
                  warehouseNameAr: resolved.nameAr,
                  shelvesCount: shelves,
                  occupancyPercent: 0.85,
                  pricePerShelf: resolved.price,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[MerchantDataProvider] Error parsing local rental invoices: $e');
      }
    }

    _activeSubscriptions = leasesMap.values.toList();
    _totalShelves = _activeSubscriptions.fold(0, (sum, item) => sum + item.shelvesCount);
    _activeHubsCount = _activeSubscriptions.length;
  }

  // ─── 2. Products & Stock Value ───────────────────────────────────────────
  Future<void> _syncProductsAndStockValue(String? sellerId) async {
    double stockValue = 0.0;

    try {
      final products = await _marketplaceService.getProducts();
      for (var p in products) {
        stockValue += (p.price * p.quantity);
      }
    } catch (e) {
      debugPrint('[MerchantDataProvider] Error syncing products: $e');
    }

    _totalStockValue = stockValue;
  }

  // ─── 3. Orders & Wallet Balance ──────────────────────────────────────────
  Future<void> _syncOrdersAndWallet(String? sellerId) async {
    int pendingCount = 0;
    double grossDelivered = 0.0;

    try {
      if (sellerId != null) {
        final ordersRes = await _supabase
            .from('sme_orders')
            .select('id, status, total_amount')
            .eq('seller_id', sellerId);

        for (var o in (ordersRes as List)) {
          final status = (o['status'] ?? '').toString().toLowerCase();
          final amount = (o['total_amount'] as num?)?.toDouble() ?? 0.0;

          if (['pending', 'confirmed', 'preparing', 'ready_for_shipment'].contains(status)) {
            pendingCount++;
          }
          if (status == 'delivered') {
            grossDelivered += amount;
          }
        }

        try {
          final buyerRes = await _supabase
              .from('buyer_orders')
              .select('id, order_status, total_amount')
              .eq('seller_id', sellerId);

          for (var o in (buyerRes as List)) {
            final status = (o['order_status'] ?? '').toString().toLowerCase();
            final amount = (o['total_amount'] as num?)?.toDouble() ?? 0.0;

            if (['pending', 'confirmed', 'preparing', 'ready_for_shipment'].contains(status)) {
              pendingCount++;
            }
            if (status == 'delivered') {
              grossDelivered += amount;
            }
          }
        } catch (_) {}

        // Query Supabase wallets table if migrated
        try {
          final merchantRes = await _supabase
              .from('merchants')
              .select('id')
              .eq('user_id', sellerId)
              .maybeSingle();

          if (merchantRes != null && merchantRes['id'] != null) {
            final walletRes = await _supabase
                .from('wallets')
                .select('available_balance_cents')
                .eq('merchant_id', merchantRes['id'])
                .maybeSingle();

            if (walletRes != null && walletRes['available_balance_cents'] != null) {
              _walletBalance = (walletRes['available_balance_cents'] as num).toDouble() / 100.0;
              _pendingOrdersCount = pendingCount;
              return;
            }
          }
        } catch (_) {
          // Table 'merchants' not migrated to Supabase instance yet — fallback to standard calculation
        }
      }
    } catch (e) {
      debugPrint('[MerchantDataProvider] Note syncing orders: $e');
    }

    _pendingOrdersCount = pendingCount;
    _walletBalance = grossDelivered * 0.95; // 95% payout after 5% platform fee
  }

  // ─── 4. Recent Activities & Invoices ─────────────────────────────────────
  Future<void> _syncRecentActivities(String? sellerId) async {
    try {
      final activities = await _marketplaceService.getRecentActivity(limit: 15);
      _recentActivities = activities;

      final pendingInvoices = activities.where((a) => a.type == ActivityType.invoice && a.subtitle.contains('PENDING')).toList();
      _pendingInvoicesCount = pendingInvoices.length;
      _pendingInvoicesTotal = pendingInvoices.fold(0.0, (acc, item) {
        final match = RegExp(r'([\d.]+)\s*AED').firstMatch(item.subtitle);
        if (match != null) {
          return acc + (double.tryParse(match.group(1) ?? '0') ?? 0.0);
        }
        return acc;
      });
    } catch (e) {
      debugPrint('[MerchantDataProvider] Error syncing activities: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DIRECT REFRESH TRIGGERS (Invoked by UI Actions)
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> refreshProducts() async {
    final user = _supabase.auth.currentUser;
    await _syncProductsAndStockValue(user?.id);
    await _persistToLocalCache();
    notifyListeners();
  }

  Future<void> refreshOrders() async {
    final user = _supabase.auth.currentUser;
    await _syncOrdersAndWallet(user?.id);
    await _syncRecentActivities(user?.id);
    await _persistToLocalCache();
    notifyListeners();
  }

  Future<void> refreshShelves() async {
    final user = _supabase.auth.currentUser;
    await _syncSubscriptions(user?.id);
    await _persistToLocalCache();
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    MarketplaceService.updateNotifier.removeListener(_onMarketplaceServiceUpdated);
    super.dispose();
  }
}
