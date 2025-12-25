class StockSummary {
  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int suppliers; // Using this for "Total Shelves" for now to minimize breaking changes, or add new field
  final double totalValue;
  final List<dynamic> activeRentals;

  const StockSummary({
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.suppliers,
    this.totalValue = 0.0,
    this.activeRentals = const [],
  });

  factory StockSummary.fromJson(Map<String, dynamic> j) => StockSummary(
    inStock: j['inStock'] ?? 0,
    lowStock: j['lowStock'] ?? 0,
    outOfStock: j['outOfStock'] ?? 0,
    suppliers: j['suppliers'] ?? 0,
    totalValue: (j['totalValue'] as num?)?.toDouble() ?? 0.0,
    activeRentals: j['activeRentals'] ?? [],
  );
}

class StockPoint {
  final String label; // e.g., category or bay
  final num value;

  const StockPoint(this.label, this.value);

  factory StockPoint.fromJson(Map<String, dynamic> j) =>
      StockPoint(j['label'] as String, j['value'] as num);
}
