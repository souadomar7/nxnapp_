import 'package:isar/isar.dart';
import '../../domain/entities/inventory_item.dart';

part 'inventory_dto.g.dart';

@collection
class InventoryDto {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String inventoryId;

  late String sellerId;
  String? productId;
  String? productName;
  late int quantity;
  String? shelfId;
  late String status;
  late DateTime createdAt;

  InventoryDto();

  factory InventoryDto.fromJson(Map<String, dynamic> json) {
    return InventoryDto()
      ..inventoryId = json['id']
      ..sellerId = json['seller_id'] ?? ''
      ..productId = json['product_id']
      ..productName = json['product_name']
      ..quantity = json['quantity'] ?? 0
      ..shelfId = json['shelf_id']
      ..status = json['status'] ?? 'active'
      ..createdAt = json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': inventoryId,
      'seller_id': sellerId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'shelf_id': shelfId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  InventoryItem toDomain() {
    return InventoryItem(
      id: inventoryId,
      sellerId: sellerId,
      productId: productId,
      productName: productName,
      shelfId: shelfId,
      quantity: quantity,
      status: status,
      createdAt: createdAt,
    );
  }

  static InventoryDto fromDomain(InventoryItem domain) {
    return InventoryDto()
      ..inventoryId = domain.id
      ..sellerId = domain.sellerId
      ..productId = domain.productId
      ..productName = domain.productName
      ..quantity = domain.quantity
      ..shelfId = domain.shelfId
      ..status = domain.status
      ..createdAt = domain.createdAt;
  }
}
