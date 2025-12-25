import 'inventory_models.dart';

abstract class InventoryService {
  Future<StockSummary> fetchSummary();
  Future<List<StockPoint>> fetchSeries();        // chart data
  Future<bool> requestDelivery();                // create delivery order
  Future<bool> createRestock();                  // create restock order
  Future<String?> openReportsUrl();              // return a URL (or null)
}
