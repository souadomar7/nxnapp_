// lib/data/receive_result.dart
class ReceiveResult {
  final String storageNo;
  final String bay;
  final int workers;
  final DateTime scheduledAt;
  final String storageMode;

  // extra fields from "Additional services" & notes
  final bool damagePhotosByAdmin;     // warehouse admin documents damaged items
  final bool listingPhotosService;    // online listing photos (value-added)
  final String notes;                 // optional notes for warehouse admin

  const ReceiveResult({
    required this.storageNo,
    required this.bay,
    required this.workers,
    required this.scheduledAt,
    required this.storageMode,
    required this.damagePhotosByAdmin,
    required this.listingPhotosService,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'storageNo': storageNo,
      'bay': bay,
      'workers': workers,
      'scheduledAt': scheduledAt.toIso8601String(),
      'storageMode': storageMode,
      'damagePhotosByAdmin': damagePhotosByAdmin,
      'listingPhotosService': listingPhotosService,
      'notes': notes,
    };
  }

  factory ReceiveResult.fromMap(Map<String, dynamic> map) {
    return ReceiveResult(
      storageNo: map['storageNo'] as String,
      bay: map['bay'] as String,
      workers: map['workers'] as int,
      scheduledAt: DateTime.parse(map['scheduledAt'] as String),
      storageMode: map['storageMode'] as String,
      damagePhotosByAdmin: map['damagePhotosByAdmin'] as bool,
      listingPhotosService: map['listingPhotosService'] as bool,
      notes: map['notes'] as String,
    );
  }
}
