import 'package:isar/isar.dart';
import '../../../../../models/marketplace_models.dart';

part 'local_inventory_item.g.dart';

@collection
class LocalInventoryItem {
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

  SmeInventory toDomain() {
    return SmeInventory(
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

  static LocalInventoryItem fromDomain(SmeInventory domain) {
    return LocalInventoryItem()
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
