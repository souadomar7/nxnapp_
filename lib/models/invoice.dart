enum InvoiceType {
  generic,
  rental,
  delivery,
}

class Invoice {
  final String id;
  final String number;
  final String warehouseName;
  final DateTime date;
  final double amount; // AED (subtotal)
  final double vat;    // AED (e.g., 5% of subtotal)
  final double workerFee; // AED (optional assistance fee)
  final bool paid;
  
  // Metadata for Activity Logging
  final InvoiceType type;
  final Map<String, dynamic>? metaData;

  const Invoice({
    required this.id,
    required this.number,
    required this.warehouseName,
    required this.date,
    required this.amount,
    required this.vat,
    this.workerFee = 0.0,
    this.paid = false,
    this.type = InvoiceType.generic,
    this.metaData,
  });

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
      id: json['id'] as String,
      number: json['invoice_number'] as String? ?? 'UNKNOWN',
      warehouseName: json['warehouse_name'] as String? ?? '',
      date: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
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
