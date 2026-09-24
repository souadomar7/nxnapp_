import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides platform-wide configuration fetched from the `platform_settings`
/// Supabase table. The table uses a key/value schema:
///   { key: String, value: String }
class PlatformSettingsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  double _vatRate = 0.05;
  double _platformFeeRate = 0.05;
  double _shelfBasePriceAed = 100.0;
  double _workerFeePerUnitAed = 50.0;
  int _freeProductListingLimit = 5;
  int _sellerPayoutHoldDays = 14;
  bool _isLoaded = false;

  double get vatRate => _vatRate;
  double get platformFeeRate => _platformFeeRate;
  double get shelfBasePriceAed => _shelfBasePriceAed;
  double get workerFeePerUnitAed => _workerFeePerUnitAed;
  int get freeProductListingLimit => _freeProductListingLimit;
  int get sellerPayoutHoldDays => _sellerPayoutHoldDays;
  bool get isLoaded => _isLoaded;

  PlatformSettingsProvider() {
    reload();
  }

  Future<void> reload() async {
    try {
      final rows = await _supabase.from('platform_settings').select();
      final map = <String, String>{};
      for (final row in rows as List) {
        map[row['key'] as String] = row['value'] as String;
      }
      _vatRate = double.tryParse(map['vat_rate'] ?? '') ?? 0.05;
      _platformFeeRate =
          double.tryParse(map['platform_fee_rate'] ?? '') ?? 0.05;
      _shelfBasePriceAed =
          double.tryParse(map['shelf_base_price_aed'] ?? '') ?? 100.0;
      _workerFeePerUnitAed =
          double.tryParse(map['worker_fee_per_unit_aed'] ?? '') ?? 50.0;
      _freeProductListingLimit =
          int.tryParse(map['free_product_listing_limit'] ?? '') ?? 5;
      _sellerPayoutHoldDays =
          int.tryParse(map['seller_payout_hold_days'] ?? '') ?? 14;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('PlatformSettingsProvider: failed to load — $e');
      _isLoaded = true;
      notifyListeners();
    }
  }
}
