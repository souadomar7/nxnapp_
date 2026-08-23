
class SmeProduct {
  final String id;
  final String sellerId;
  final String? inventoryId; // 1:1 Link to sme_inventory row
  final String name;
  final String? nameAr;
  final String? description;
  final double price;
  final String? photoUrl;
  final String? shopName;
  final bool isShopApproved; // renamed from isShopVerified — matches is_approved column
  final bool isHidden; // Content moderation flag
  final String? hiddenReason;
  final DateTime createdAt;

  String getLocalizedName(bool isAr) {
    if (isAr) {
      if (nameAr != null && nameAr!.isNotEmpty) return nameAr!;
      final lower = name.toLowerCase();
      if (lower.contains('espresso') || lower.contains('beans')) return 'حبوب إسبريسو فاخرة';
      if (lower.contains('earbuds') || lower.contains('wireless')) return 'سماعات لاسلكية برو';
      if (lower.contains('flower') || lower.contains('rose')) return 'باقة زهور طبيعية';
      if (lower.contains('inbound') || lower.contains('sto')) return 'دفعة شحنة واردة (STO)';
      if (lower.contains('honey')) return 'عسل طبيعي إماراتي';
      if (lower.contains('olive oil')) return 'زيت زيتون عضوي';
      if (lower.contains('coffee')) return 'مستخلص القهوة';
      if (lower.contains('milk')) return 'حليب طازج';
      if (lower.contains('berry')) return 'توت مجمد مشكل';
      return name;
    }
    return name;
  }

  String getLocalizedDescription(bool isAr) {
    if (isAr && description != null) {
      return description!
          .replaceAll('Locally roasted in Dubai, UAE. Rich flavor profile with hints of dark chocolate.', 'محموص محلياً في دبي، الإمارات. نكهة غنية مع لمسات من الشوكولاتة الداكنة.')
          .replaceAll('Active noise cancellation with up to 30 hours of total playtime.', 'خاصية إلغاء الضوضاء النشطة مع بطارية تدوم حتى 30 ساعة تشغيل.')
          .replaceAll('No description provided.', 'لا يوجد وصف متاح للمنتج.');
    }
    return description ?? (isAr ? 'لا يوجد وصف متاح للمنتج.' : 'No description provided.');
  }

  String get sku => id;

  SmeProduct({
    required this.id,
    required this.sellerId,
    this.inventoryId,
    required this.name,
    this.nameAr,
    this.description,
    required this.price,
    this.photoUrl,
    this.shopName,
    this.isShopApproved = false,
    this.isHidden = false,
    this.hiddenReason,
    required this.createdAt,
  });

  factory SmeProduct.fromJson(Map<String, dynamic> json) {
    return SmeProduct(
      id: json['id'],
      sellerId: json['seller_id'],
      inventoryId: json['inventory_id'],
      name: json['name'],
      nameAr: json['name_ar'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      photoUrl: json['photo_url'],
      shopName: json['shop_name'],
      isShopApproved: json['is_shop_approved'] ?? json['is_shop_verified'] ?? false,
      isHidden: json['is_hidden'] ?? false,
      hiddenReason: json['hidden_reason'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      if (inventoryId != null) 'inventory_id': inventoryId,
      'name': name,
      'description': description,
      'price': price,
      'photo_url': photoUrl,
      'is_hidden': isHidden,
      if (hiddenReason != null) 'hidden_reason': hiddenReason,
    };
  }
}

class SmeInventory {
  final String id;
  final String sellerId;
  final String? productId;
  final String? productName;
  final String? shelfId;
  final int quantity;
  final String status;
  final DateTime createdAt;
  final String? sku;
  final String? warehouseName;
  final String? shelfLocation;
  final double? totalValue;

  SmeInventory({
    required this.id,
    required this.sellerId,
    this.productId,
    this.productName,
    this.shelfId,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.sku,
    this.warehouseName,
    this.shelfLocation,
    this.totalValue,
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
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      sku: json['sku'] ?? json['product_id'] ?? json['id'],
      warehouseName: json['warehouse_name'] ?? 'Dubai Central Hub',
      shelfLocation: json['shelf_location'] ?? json['shelf_id'] ?? 'Bay 3',
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String getLocalizedProductName(bool isAr) {
    final raw = productName ?? 'منتج مخزون';
    if (!isAr) return raw;
    final lower = raw.toLowerCase();
    if (lower.contains('inbound batch') || lower.contains('sto')) {
      return raw.replaceAll('Inbound Batch', 'دفعة شحنة واردة');
    }
    if (lower.contains('espresso') || lower.contains('beans')) return 'حبوب إسبريسو فاخرة';
    if (lower.contains('earbuds') || lower.contains('wireless')) return 'سماعات لاسلكية برو';
    if (lower.contains('flower') || lower.contains('rose')) return 'باقة زهور طبيعية';
    if (lower.contains('cold brew')) return 'مستخلص القهوة الباردة';
    if (lower.contains('olive oil')) return 'زيت زيتون عضوي 1 لتر';
    if (lower.contains('almond milk')) return 'حليب اللوز (12×1 لتر)';
    if (lower.contains('berry')) return 'توت مجمد مشكل 500غ';
    if (lower.contains('honey')) return 'عسل طبيعي 500غ';
    return raw;
  }

  String getLocalizedWarehouseName(bool isAr) {
    final raw = warehouseName ?? 'Dubai Central Hub';
    if (!isAr) return raw;
    if (raw.contains('Dubai') || raw.contains('dxb')) return 'مستودع دبي المركزي';
    if (raw.contains('Abu Dhabi') || raw.contains('auh')) return 'مستودع أبوظبي المركزي';
    if (raw.contains('Sharjah') || raw.contains('shj')) return 'مستودع الشارقة المركزي';
    if (raw.contains('Al Ain') || raw.contains('aln')) return 'مستودع العين المركزي';
    return raw;
  }

  String getLocalizedStatus(bool isAr) {
    if (!isAr) {
      if (status == 'in_stock') return 'In Stock';
      if (status == 'low_stock') return 'Low Stock';
      if (status == 'out_of_stock') return 'Out of Stock';
      if (status == 'quarantine') return 'Quarantine';
      return status;
    }
    if (status == 'in_stock') return 'متوفر';
    if (status == 'low_stock') return 'مخزون منخفض';
    if (status == 'out_of_stock') return 'نفذ المخزون';
    if (status == 'quarantine') return 'تحت العزل';
    return status;
  }
}

class SmeInboundRequest {
  final String id;
  final String sellerId;
  final DateTime? expectedDate;
  final int? itemCount;
  final String status;
  final String? notes;
  final bool needsPrep;
  final int workersRequested;
  /// Computed by DB as workers_requested × 50 AED.
  /// Null when reading from local storage (no DB).
  final double? workersFee;
  final DateTime createdAt;

  SmeInboundRequest({
    required this.id,
    required this.sellerId,
    this.expectedDate,
    this.itemCount,
    required this.status,
    this.notes,
    this.needsPrep = false,
    this.workersRequested = 0,
    this.workersFee,
    required this.createdAt,
  });

  factory SmeInboundRequest.fromJson(Map<String, dynamic> json) {
    return SmeInboundRequest(
      id: json['id'],
      sellerId: json['seller_id'],
      expectedDate:
          json['expected_date'] != null ? DateTime.parse(json['expected_date']) : null,
      itemCount: json['item_count'],
      status: json['status'],
      notes: json['notes'],
      needsPrep: json['needs_prep'] ?? false,
      workersRequested: json['workers_requested'] ?? 0,
      workersFee: json['workers_fee'] != null
          ? (json['workers_fee'] as num).toDouble()
          : null,
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
  // New delivery fields (spec v2)
  final String recipientPhone;
  final String? recipientNotes;
  /// 'domestic' | 'international'
  final String deliveryMode;
  final String? emirate;
  final String? country;
  final String? city;
  final String? shippingCompanyId;
  final String? warehouseId;
  final DateTime createdAt;

  SmeOrder({
    required this.id,
    required this.sellerId,
    this.customerName,
    this.customerAddress,
    this.deliveryMethod,
    required this.status,
    this.totalAmount,
    this.recipientPhone = '',
    this.recipientNotes,
    this.deliveryMode = 'domestic',
    this.emirate,
    this.country,
    this.city,
    this.shippingCompanyId,
    this.warehouseId,
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
      totalAmount:
          json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : null,
      recipientPhone: json['recipient_phone'] ?? '',
      recipientNotes: json['recipient_notes'],
      deliveryMode: json['delivery_mode'] ?? 'domestic',
      emirate: json['emirate'],
      country: json['country'],
      city: json['city'],
      shippingCompanyId: json['shipping_company_id'],
      warehouseId: json['warehouse_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'customer_name': customerName,
    'customer_address': customerAddress,
    'delivery_method': deliveryMethod,
    'status': status,
    'total_amount': totalAmount,
    'recipient_phone': recipientPhone,
    'recipient_notes': recipientNotes,
    'delivery_mode': deliveryMode,
    'emirate': emirate,
    'country': country,
    'city': city,
    'shipping_company_id': shippingCompanyId,
    'warehouse_id': warehouseId,
    'created_at': createdAt.toIso8601String(),
  };
}

class MarketplaceShop {
  final String id;
  final String sellerId;
  final String shopName;
  final String licenseName;
  final String? licenseDocumentUrl; // Trade license scanned document URL
  /// Admin-controlled approval gate. Unapproved shops/products are invisible
  /// to public buyers. Free action — admin approves manually.
  final bool isApproved;
  /// Paid upsell. Grants: (1) top-ranked placement, (2) unlimited products.
  /// Independent of isApproved.
  final bool isFeatured;
  /// When null or in the past, featured status has lapsed.
  final DateTime? featuredUntil;
  final DateTime createdAt;

  MarketplaceShop({
    required this.id,
    required this.sellerId,
    required this.shopName,
    required this.licenseName,
    this.licenseDocumentUrl,
    required this.isApproved,
    this.isFeatured = false,
    this.featuredUntil,
    required this.createdAt,
  });

  /// Whether the featured subscription is currently active.
  bool get featuredActive =>
      isFeatured &&
      (featuredUntil == null || featuredUntil!.isAfter(DateTime.now()));

  factory MarketplaceShop.fromJson(Map<String, dynamic> json) {
    return MarketplaceShop(
      id: json['id'],
      sellerId: json['seller_id'],
      shopName: json['shop_name'],
      licenseName: json['license_name'],
      licenseDocumentUrl: json['license_document_url'],
      // Support both old 'is_verified' key (pre-migration) and new 'is_approved'
      isApproved: json['is_approved'] ?? json['is_verified'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      featuredUntil: json['featured_until'] != null
          ? DateTime.parse(json['featured_until'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'shop_name': shopName,
      'license_name': licenseName,
      if (licenseDocumentUrl != null) 'license_document_url': licenseDocumentUrl,
      'is_approved': isApproved,
      'is_featured': isFeatured,
      if (featuredUntil != null) 'featured_until': featuredUntil!.toIso8601String(),
    };
  }
}

/// Lightweight model for the shipping_companies lookup table.
class ShippingCompany {
  final String id;
  final String name;
  final bool active;

  const ShippingCompany({
    required this.id,
    required this.name,
    this.active = true,
  });

  factory ShippingCompany.fromJson(Map<String, dynamic> json) {
    return ShippingCompany(
      id: json['id'],
      name: json['name'],
      active: json['active'] ?? true,
    );
  }
}

/// Informational damage/inspection report attached to an inbound request.
/// No automatic invoice or blocking action — admin uses this for records only.
class InboundInspectionReport {
  final String id;
  final String inboundRequestId;
  final String itemDescription;
  final bool isDamaged;
  final List<String> photoUrls;
  final String? notes;
  final String? inspectedBy;
  final DateTime inspectedAt;

  const InboundInspectionReport({
    required this.id,
    required this.inboundRequestId,
    required this.itemDescription,
    required this.isDamaged,
    required this.photoUrls,
    this.notes,
    this.inspectedBy,
    required this.inspectedAt,
  });

  factory InboundInspectionReport.fromJson(Map<String, dynamic> json) {
    return InboundInspectionReport(
      id: json['id'],
      inboundRequestId: json['inbound_request_id'],
      itemDescription: json['item_description'],
      isDamaged: json['is_damaged'] ?? false,
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
      notes: json['notes'],
      inspectedBy: json['inspected_by'],
      inspectedAt: DateTime.parse(json['inspected_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'inbound_request_id': inboundRequestId,
    'item_description': itemDescription,
    'is_damaged': isDamaged,
    'photo_urls': photoUrls,
    'notes': notes,
    'inspected_by': inspectedBy,
  };
}

/// Represents an item in the buyer's marketplace shopping cart.
class CartItem {
  final SmeProduct product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

/// Model for buyer marketplace purchases.
class BuyerOrder {
  final String id;
  final String? buyerId;
  final String buyerName;
  final String buyerPhone;
  final String? buyerEmail;
  final String productId;
  final String sellerId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String deliveryAddress;
  final String paymentStatus;
  final String? fulfillmentOrderId;
  final DateTime createdAt;

  BuyerOrder({
    required this.id,
    this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerEmail,
    required this.productId,
    required this.sellerId,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalAmount,
    required this.deliveryAddress,
    this.paymentStatus = 'paid',
    this.fulfillmentOrderId,
    required this.createdAt,
  });

  factory BuyerOrder.fromJson(Map<String, dynamic> json) {
    return BuyerOrder(
      id: json['id'],
      buyerId: json['buyer_id'],
      buyerName: json['buyer_name'],
      buyerPhone: json['buyer_phone'],
      buyerEmail: json['buyer_email'],
      productId: json['product_id'],
      sellerId: json['seller_id'],
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      deliveryAddress: json['delivery_address'],
      paymentStatus: json['payment_status'] ?? 'paid',
      fulfillmentOrderId: json['fulfillment_order_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class SellerPayoutRequest {
  final String id;
  final String sellerId;
  final String iban;
  final String bankName;
  final double requestedAmount;
  final double platformCommission;
  final double netPayout;
  final String status; // 'pending_clearance', 'available', 'requested', 'completed'
  final DateTime clearanceDueAt;
  final String? transferReference;
  final DateTime createdAt;

  SellerPayoutRequest({
    required this.id,
    required this.sellerId,
    required this.iban,
    required this.bankName,
    required this.requestedAmount,
    required this.platformCommission,
    required this.netPayout,
    required this.status,
    required this.clearanceDueAt,
    this.transferReference,
    required this.createdAt,
  });

  factory SellerPayoutRequest.fromJson(Map<String, dynamic> json) {
    return SellerPayoutRequest(
      id: json['id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      iban: json['iban'] ?? '',
      bankName: json['bank_name'] ?? 'UAE Central Bank',
      requestedAmount: (json['requested_amount'] as num?)?.toDouble() ?? 0.0,
      platformCommission: (json['platform_commission'] as num?)?.toDouble() ?? 0.0,
      netPayout: (json['net_payout'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending_clearance',
      clearanceDueAt: DateTime.tryParse(json['clearance_due_at'] ?? '') ?? DateTime.now().add(const Duration(days: 14)),
      transferReference: json['transfer_reference'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class CourierShipmentTrack {
  final String id;
  final String orderId;
  final String courierName; // 'Aramex', 'Fetchr', 'Careem Box'
  final String waybillNumber;
  final String trackingUrl;
  final String status; // 'label_created', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered'
  final double? latitude;
  final double? longitude;
  final DateTime updatedAt;

  CourierShipmentTrack({
    required this.id,
    required this.orderId,
    required this.courierName,
    required this.waybillNumber,
    required this.trackingUrl,
    required this.status,
    this.latitude,
    this.longitude,
    required this.updatedAt,
  });

  factory CourierShipmentTrack.fromJson(Map<String, dynamic> json) {
    return CourierShipmentTrack(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      courierName: json['courier_name'] ?? 'Aramex UAE',
      waybillNumber: json['waybill_number'] ?? '',
      trackingUrl: json['tracking_url'] ?? '',
      status: json['status'] ?? 'label_created',
      latitude: (json['current_latitude'] as num?)?.toDouble(),
      longitude: (json['current_longitude'] as num?)?.toDouble(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
