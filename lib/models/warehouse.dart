class Warehouse {
  final String id;
  final String name;
  final String? nameAr; // Made nullable to match schema safely
  final String emirate;
  final String? emirateAr;
  final List<String> amenities;
  final List<String> amenitiesAr;
  final int shelvesAvailable;
  final double pricePerShelf;
  final bool is24h;
  final double? lat;
  final double? lng;

  Warehouse({
    required this.id,
    required this.name,
    this.nameAr,
    required this.emirate,
    this.emirateAr,
    required this.shelvesAvailable,
    required this.pricePerShelf,
    required this.is24h,
    required this.amenities,
    required this.amenitiesAr,
    this.lat,
    this.lng,
  });

  String getLocalizedName(bool isAr) {
    if (isAr) {
      if (nameAr != null && nameAr!.trim().isNotEmpty) return nameAr!;
      if (name.contains('Dubai Central')) return 'مستودع دبي المركزي';
      if (name.contains('Sharjah Regional')) return 'مستودع الشارقة الإقليمي';
      if (name.contains('Abu Dhabi Central')) return 'مستودع أبوظبي المركزي';
      if (name.contains('Al Ain Central')) return 'مستودع العين المركزي';
      return name.replaceAll('Warehouse', 'مستودع').replaceAll('Hub', 'مركز');
    }
    return name;
  }

  String getLocalizedEmirate(bool isAr) {
    if (isAr) {
      if (emirateAr != null && emirateAr!.trim().isNotEmpty) return emirateAr!;
      switch (emirate.toLowerCase()) {
        case 'dubai': return 'دبي';
        case 'abu dhabi': return 'أبوظبي';
        case 'sharjah': return 'الشارقة';
        case 'al ain': return 'العين';
        case 'ajman': return 'عجمان';
        case 'ras al khaimah': return 'رأس الخيمة';
        case 'fujairah': return 'الفجيرة';
        case 'umm al quwain': return 'أم القيوين';
        default: return emirate;
      }
    }
    return emirate;
  }

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String?,
      emirate: json['emirate'] as String,
      // For demo purposes, we might not have emirate_ar in DB yet or it's just 'emirate'
      emirateAr: json['emirate_ar'] ?? json['emirate'], 
      shelvesAvailable: json['total_shelves'] ?? 0,
      pricePerShelf: (json['price_per_month'] as num?)?.toDouble() ?? (json['price_per_shelf'] as num?)?.toDouble() ?? 100.0,
      is24h: true, // Schema doesn't have is24h yet, default true
      amenities: [], // Schema doesn't have amenities yet
      amenitiesAr: [],
      lat: (json['location_lat'] as num?)?.toDouble(),
      lng: (json['location_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'emirate': emirate,
      'location_lat': lat,
      'location_lng': lng,
      'total_shelves': shelvesAvailable,
      'price_per_shelf': pricePerShelf,
    };
  }
}
