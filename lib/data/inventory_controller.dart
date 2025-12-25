import 'package:flutter/foundation.dart';
import 'inventory_models.dart';
import 'inventory_service.dart';

class InventoryController extends ChangeNotifier {
  final InventoryService service;

  InventoryController(this.service);

  bool loading = false;
  StockSummary summary = const StockSummary(inStock: 0, lowStock: 0, outOfStock: 0, suppliers: 0);
  List<StockPoint> series = const [];

  Future<void> load() async {
    loading = true; notifyListeners();
    try {
      final results = await Future.wait([service.fetchSummary(), service.fetchSeries()]);
      summary = results[0] as StockSummary;
      series  = results[1] as List<StockPoint>;
    } finally {
      loading = false; notifyListeners();
    }
  }

  Future<bool> requestDelivery() async {
    final ok = await service.requestDelivery();
    if (ok) await load();
    return ok;
  }

  Future<bool> restock() async {
    final ok = await service.createRestock();
    if (ok) await load();
    return ok;
  }

  Future<String?> openReports() => service.openReportsUrl();
}
