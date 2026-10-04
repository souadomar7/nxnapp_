enum InvoiceType {
  generic,
  rental,
  delivery,
}

class Invoice {
  final String id;
  final String number;
  final String warehouseName;
  final String? warehouseNameAr;
  final DateTime date;
  final double amount; // AED (subtotal)
  final double vat;    // AED (e.g., 5% of subtotal)
  final double workerFee; // AED (optional assistance fee)
  final bool paid;
  final InvoiceType type;
  final Map<String, dynamic>? metaData;
  
  // FTA E-Invoicing Metadata
  final String? trnNumber;
  final String bilingualSupplierNameEn;
  final String bilingualSupplierNameAr;

  const Invoice({
    required this.id,
    required this.number,
    required this.warehouseName,
    this.warehouseNameAr,
    required this.date,
    required this.amount,
    required this.vat,
    this.workerFee = 0.0,
    this.paid = false,
    this.type = InvoiceType.generic,
    this.metaData,
    this.trnNumber = '100492817300003', // FTA 15-digit TRN
    this.bilingualSupplierNameEn = 'NXN Hub Logistics L.L.C.',
    this.bilingualSupplierNameAr = 'الشبكة الوطنية للخدمات اللوجستية ش.ذ.م.م',
  });

  String getWarehouseName(bool isAr) {
    if (warehouseNameAr != null && warehouseNameAr!.trim().isNotEmpty && isAr) {
      return warehouseNameAr!;
    }
    final raw = warehouseName.toLowerCase();
    
    if (raw == 'auh' || raw == 'wh-auh' || raw.contains('abu dhabi') || raw.contains('auh') || raw.contains('أبوظبي') || raw.contains('أبو ظبي')) {
      return isAr ? 'مستودع أبوظبي المركزي (كيزاد)' : 'Abu Dhabi Central Warehouse (KIZAD)';
    }
    if (raw == 'shj' || raw == 'wh-shj' || raw.contains('sharjah') || raw.contains('shj') || raw.contains('الشارقة')) {
      return isAr ? 'مستودع الشارقة الإقليمي (المنطقة 4)' : 'Sharjah Regional Hub (Industrial 4)';
    }
    if (raw == 'aln' || raw == 'wh-aln' || raw.contains('al ain') || raw.contains('aln') || raw.contains('العين')) {
      return isAr ? 'مستودع العين اللوجستي (الصناعية)' : 'Al Ain Logistics Oasis (Sanaiya)';
    }
    if (raw == 'dxb' || raw == 'wh-dxb' || raw.contains('dubai') || raw.contains('dxb') || raw.contains('دبي')) {
      return isAr ? 'مستودع دبي المركزي (القوز)' : 'Dubai Central Warehouse (Al Quoz)';
    }
    if (raw.contains('marketplace dispatch') || raw.contains('nxn marketplace dispatch')) {
      return isAr ? 'خدمة شحن سوق NXN' : 'NXN Marketplace Dispatch';
    }
    if (raw.contains('marketplace') || raw.contains('nxn marketplace')) {
      return isAr ? 'سوق NXN للتجارة' : 'NXN Marketplace';
    }
    if (raw.contains('single/multi warehouse booking') || raw.contains('warehouse booking')) {
      return isAr ? 'حجز مساحات تخزين متعددة' : 'Warehouse Space Lease';
    }
    if (raw.contains('shop verification setup fee')) {
      return isAr ? 'رسوم توثيق وتفعيل المتجر' : 'Shop Verification Setup Fee';
    }
    if (raw.contains('delivery service')) {
      return isAr ? 'خدمة توصيل الطلبات' : 'Delivery Service';
    }
    if (raw.contains('iban settlement payout')) {
      return isAr ? 'سحب تسوية الحساب المصرفي (IBAN)' : 'IBAN Settlement Payout';
    }

    if (isAr) {
      return warehouseName.replaceAll('Warehouse', 'مستودع').replaceAll('Hub', 'مركز');
    }
    return warehouseName;
  }

  double get total => amount + vat + workerFee;

  String get formattedDate =>
      "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year}";
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': number,
      'warehouse_name': warehouseName,
      'warehouse_name_ar': warehouseNameAr,
      'amount': amount,
      'vat': vat,
      'worker_fee': workerFee,
      'paid': paid,
      'type': type.name, // "rental", "delivery", "generic"
      'metadata': metaData,
      'created_at': date.toIso8601String(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: (json['id'] as String?) ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
      number: (json['invoice_number'] as String?) ?? (json['number'] as String?) ?? 'INV-001',
      warehouseName: (json['warehouse_name'] as String?) ?? 'DXB Central Hub',
      warehouseNameAr: json['warehouse_name_ar'] as String?,
      date: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0.0,
      workerFee: (json['worker_fee'] as num?)?.toDouble() ?? 0.0,
      paid: json['paid'] as bool? ?? false,
      type: InvoiceType.values.firstWhere(
            (e) => e.name == (json['type'] as String? ?? 'generic'),
        orElse: () => InvoiceType.generic,
      ),
      metaData: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
