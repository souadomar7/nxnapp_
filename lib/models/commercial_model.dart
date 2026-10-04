/// Commercial and Pricing Configuration for SMEs & Home Sellers
class CommercialModel {
  // Storage Fees (Standard Shelf for Home Sellers)
  static const double baseShelfMonthlyRate = 100.0; // AED per standard shelf / month
  static const double standardShelfMaxWeightKg = 500.0; // 500 kg per shelf

  // Contract Duration Discounts
  static const double discount1Month = 0.0; // 0%
  static const double discount3Months = 0.05; // 5% (AED 95/month)
  static const double discount6Months = 0.10; // 10% (AED 90/month)
  static const double discount12Months = 0.20; // 20% (AED 80/month)

  // Platform Commission Fees
  static const double platformCommissionRate = 0.05; // 5% on marketplace sales / fulfillment
  static const double uaeVatRate = 0.05; // 5% UAE FTA VAT

  // Delivery Service Fees (Domestic UAE)
  static const double deliveryStandardNextDay = 15.0; // AED
  static const double deliveryExpressSameDay = 25.0; // AED
  static const double deliveryRemoteRegional = 35.0; // AED (Western Region / Hatta)
  static const double deliverySelfPickup = 0.0; // Customer Click & Collect

  // Value-Added Services (VAS)
  static const double vasProductPhotographyPerItem = 15.0; // AED per product
  static const double vasBarcodeLabelingPerUnit = 2.0; // AED per barcode label
  static const double vasQualityInspectionPerBatch = 20.0; // AED per batch inspection

  /// Calculates the shelf storage fee with duration discount
  static ShelfQuote calculateShelfQuote({
    required int shelfCount,
    required int durationMonths,
    bool includePhotography = false,
    int photographyItemCount = 0,
  }) {
    double discountRate = 0.0;
    if (durationMonths >= 12) {
      discountRate = discount12Months;
    } else if (durationMonths >= 6) {
      discountRate = discount6Months;
    } else if (durationMonths >= 3) {
      discountRate = discount3Months;
    }

    final double effectiveMonthlyRate = baseShelfMonthlyRate * (1 - discountRate);
    final double rawStorageFee = shelfCount * baseShelfMonthlyRate * durationMonths;
    final double discountedStorageFee = shelfCount * effectiveMonthlyRate * durationMonths;
    final double discountSavings = rawStorageFee - discountedStorageFee;

    final double vasFee = includePhotography
        ? (photographyItemCount > 0 ? photographyItemCount : shelfCount) * vasProductPhotographyPerItem
        : 0.0;

    final double subtotal = discountedStorageFee + vasFee;
    final double vat = subtotal * uaeVatRate;
    final double total = subtotal + vat;

    return ShelfQuote(
      shelfCount: shelfCount,
      durationMonths: durationMonths,
      baseMonthlyRate: baseShelfMonthlyRate,
      effectiveMonthlyRate: effectiveMonthlyRate,
      discountRate: discountRate,
      rawStorageFee: rawStorageFee,
      discountedStorageFee: discountedStorageFee,
      discountSavings: discountSavings,
      vasFee: vasFee,
      subtotal: subtotal,
      vat: vat,
      total: total,
    );
  }
}

class ShelfQuote {
  final int shelfCount;
  final int durationMonths;
  final double baseMonthlyRate;
  final double effectiveMonthlyRate;
  final double discountRate;
  final double rawStorageFee;
  final double discountedStorageFee;
  final double discountSavings;
  final double vasFee;
  final double subtotal;
  final double vat;
  final double total;

  const ShelfQuote({
    required this.shelfCount,
    required this.durationMonths,
    required this.baseMonthlyRate,
    required this.effectiveMonthlyRate,
    required this.discountRate,
    required this.rawStorageFee,
    required this.discountedStorageFee,
    required this.discountSavings,
    required this.vasFee,
    required this.subtotal,
    required this.vat,
    required this.total,
  });
}

/// Delivery Methods for Outbound Fulfillment
enum DeliveryMethod {
  standardNextDay,
  expressSameDay,
  remoteRegional,
  selfPickup,
}

extension DeliveryMethodExtension on DeliveryMethod {
  String get code {
    switch (this) {
      case DeliveryMethod.standardNextDay:
        return 'standard_next_day';
      case DeliveryMethod.expressSameDay:
        return 'express_same_day';
      case DeliveryMethod.remoteRegional:
        return 'remote_regional';
      case DeliveryMethod.selfPickup:
        return 'self_pickup';
    }
  }

  String label(bool isAr) {
    switch (this) {
      case DeliveryMethod.standardNextDay:
        return isAr ? 'توصيل قياسي (خلال 24 ساعة)' : 'Standard Next-Day (24h)';
      case DeliveryMethod.expressSameDay:
        return isAr ? 'توصيل سريع (نفس اليوم)' : 'Express Same-Day Delivery';
      case DeliveryMethod.remoteRegional:
        return isAr ? 'توصيل للمناطق البعيدة / الغربية' : 'Regional / Remote Area Delivery';
      case DeliveryMethod.selfPickup:
        return isAr ? 'استلام العميل من المستودع (مجاني)' : 'Customer Self-Pickup / Click & Collect';
    }
  }

  double get fee {
    switch (this) {
      case DeliveryMethod.standardNextDay:
        return CommercialModel.deliveryStandardNextDay;
      case DeliveryMethod.expressSameDay:
        return CommercialModel.deliveryExpressSameDay;
      case DeliveryMethod.remoteRegional:
        return CommercialModel.deliveryRemoteRegional;
      case DeliveryMethod.selfPickup:
        return CommercialModel.deliverySelfPickup;
    }
  }
}

/// Consignee & Order Information for Outbound Pick & Pack
class ConsigneeDetails {
  final String fullName;
  final String phone;
  final String emirate;
  final String fullAddress;
  final String? deliveryNotes;

  const ConsigneeDetails({
    required this.fullName,
    required this.phone,
    required this.emirate,
    required this.fullAddress,
    this.deliveryNotes,
  });

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'phone': phone,
        'emirate': emirate,
        'full_address': fullAddress,
        'delivery_notes': deliveryNotes,
      };

  factory ConsigneeDetails.fromJson(Map<String, dynamic> json) => ConsigneeDetails(
        fullName: json['full_name'] ?? '',
        phone: json['phone'] ?? '',
        emirate: json['emirate'] ?? 'Dubai',
        fullAddress: json['full_address'] ?? '',
        deliveryNotes: json['delivery_notes'],
      );
}

/// Outbound Fulfillment Order Model
class OutboundOrder {
  final String id;
  final String orderReference;
  final String sellerId;
  final ConsigneeDetails consignee;
  final List<OutboundOrderItem> items;
  final DeliveryMethod deliveryMethod;
  final double deliveryFee;
  final double platformFee;
  final double totalItemsAmount;
  final double totalPayable;
  final String status; // 'pending_pick', 'picked', 'packed', 'shipped', 'delivered'
  final DateTime createdAt;

  const OutboundOrder({
    required this.id,
    required this.orderReference,
    required this.sellerId,
    required this.consignee,
    required this.items,
    required this.deliveryMethod,
    required this.deliveryFee,
    required this.platformFee,
    required this.totalItemsAmount,
    required this.totalPayable,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_reference': orderReference,
        'seller_id': sellerId,
        'consignee': consignee.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'delivery_method': deliveryMethod.code,
        'delivery_fee': deliveryFee,
        'platform_fee': platformFee,
        'total_items_amount': totalItemsAmount,
        'total_payable': totalPayable,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}

class OutboundOrderItem {
  final String productId;
  final String productName;
  final String? productNameAr;
  final int quantityToPick;
  final double unitPrice;

  const OutboundOrderItem({
    required this.productId,
    required this.productName,
    this.productNameAr,
    required this.quantityToPick,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'product_name_ar': productNameAr,
        'quantity_to_pick': quantityToPick,
        'unit_price': unitPrice,
      };

  factory OutboundOrderItem.fromJson(Map<String, dynamic> json) => OutboundOrderItem(
        productId: json['product_id'] ?? '',
        productName: json['product_name'] ?? '',
        productNameAr: json['product_name_ar'],
        quantityToPick: (json['quantity_to_pick'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Inbound Intake Inspection Record (Receiving by Count & Damage Quarantine)
class InboundIntakeRecord {
  final String id;
  final String shipmentId;
  final String warehouseId;
  final int expectedCount;
  final int receivedCount;
  final int damagedCount;
  final List<String> damagePhotoUrls;
  final String? damageDescription;
  final bool requestedPhotographyVas;
  final String status; // 'verified', 'discrepancy_reported', 'quarantined'
  final DateTime inspectedAt;

  const InboundIntakeRecord({
    required this.id,
    required this.shipmentId,
    required this.warehouseId,
    required this.expectedCount,
    required this.receivedCount,
    required this.damagedCount,
    required this.damagePhotoUrls,
    this.damageDescription,
    required this.requestedPhotographyVas,
    required this.status,
    required this.inspectedAt,
  });

  int get soundUnitsCount => receivedCount - damagedCount;
  bool get hasDamages => damagedCount > 0;
  bool get hasCountMismatch => expectedCount != receivedCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'shipment_id': shipmentId,
        'warehouse_id': warehouseId,
        'expected_count': expectedCount,
        'received_count': receivedCount,
        'damaged_count': damagedCount,
        'damage_photo_urls': damagePhotoUrls,
        'damage_description': damageDescription,
        'requested_photography_vas': requestedPhotographyVas,
        'status': status,
        'inspected_at': inspectedAt.toIso8601String(),
      };
}
