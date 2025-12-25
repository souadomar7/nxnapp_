
class SmeProduct {
  final String id;
  final String sellerId;
  final String name;
  final String? description;
  final double price;
  final String? photoUrl;
  final DateTime createdAt;

  SmeProduct({
    required this.id,
    required this.sellerId,
    required this.name,
    this.description,
    required this.price,
    this.photoUrl,
    required this.createdAt,
  });

  factory SmeProduct.fromJson(Map<String, dynamic> json) {
    return SmeProduct(
      id: json['id'],
      sellerId: json['seller_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      photoUrl: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'photo_url': photoUrl,
      // created_at is usually handled by DB on insert
    };
  }
}

class SmeInventory {
  final String id;
  final String sellerId;
  final String? productId; // Can be null if not linked yet? assuming linked based on schema
  final String? productName; // Helper for UI JOIN
  final String? shelfId;
  final int quantity;
  final String status;
  final DateTime createdAt;

  SmeInventory({
    required this.id,
    required this.sellerId,
    this.productId,
    this.productName, 
    this.shelfId,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory SmeInventory.fromJson(Map<String, dynamic> json) {
    return SmeInventory(
      id: json['id'],
      sellerId: json['seller_id'],
      productId: json['product_id'],
      productName: json['sme_products'] != null ? json['sme_products']['name'] : null,
      shelfId: json['shelf_id'],
      quantity: json['quantity'] ?? 0,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SmeInboundRequest {
  final String id;
  final String sellerId;
  final DateTime? expectedDate;
  final int? itemCount;
  final String status;
  final String? notes;
  final DateTime createdAt;

  SmeInboundRequest({
    required this.id,
    required this.sellerId,
    this.expectedDate,
    this.itemCount,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory SmeInboundRequest.fromJson(Map<String, dynamic> json) {
    return SmeInboundRequest(
      id: json['id'],
      sellerId: json['seller_id'],
      expectedDate: json['expected_date'] != null ? DateTime.parse(json['expected_date']) : null,
      itemCount: json['item_count'],
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SmeOrder {
  final String id;
  final String sellerId;
  final String? customerName;
  final String? customerAddress;
  final String? deliveryMethod;
  final String status;
  final double? totalAmount;
  final DateTime createdAt;

  SmeOrder({
    required this.id,
    required this.sellerId,
    this.customerName,
    this.customerAddress,
    this.deliveryMethod,
    required this.status,
    this.totalAmount,
    required this.createdAt,
  });

  factory SmeOrder.fromJson(Map<String, dynamic> json) {
    return SmeOrder(
      id: json['id'],
      sellerId: json['seller_id'],
      customerName: json['customer_name'],
      customerAddress: json['customer_address'],
      deliveryMethod: json['delivery_method'],
      status: json['status'],
      totalAmount: json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
