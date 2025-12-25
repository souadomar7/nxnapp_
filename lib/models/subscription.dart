class SmeSubscription {
  final String id;
  final String sellerId;
  final String warehouseId;
  final int shelvesCount;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  SmeSubscription({
    required this.id,
    required this.sellerId,
    required this.warehouseId,
    required this.shelvesCount,
    required this.startDate,
    this.endDate,
    required this.isActive,
  });

  factory SmeSubscription.fromJson(Map<String, dynamic> json) {
    return SmeSubscription(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      warehouseId: json['warehouse_id'] as String,
      shelvesCount: json['shelves_count'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'warehouse_id': warehouseId,
      'shelves_count': shelvesCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
