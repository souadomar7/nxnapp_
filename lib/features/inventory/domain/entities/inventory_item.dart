class InventoryItem {
  final String id;
  final String sellerId;
  final String? productId;
  final String? productName;
  final String? shelfId;
  final int quantity;
  final String status;
  final DateTime createdAt;

  const InventoryItem({
    required this.id,
    required this.sellerId,
    this.productId,
    this.productName,
    this.shelfId,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });
}
