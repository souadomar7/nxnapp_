import 'dart:convert';

enum SyncStatus { pending, synced, failed }

class OfflineGatePass {
  final String passCode;
  final String leaseId;
  final String idempotencyKey;
  final String qrSignature;
  final String facilityName;
  final String dockGate;
  final String? driverName;
  final String? driverLicense;
  final String? vehiclePlate;
  final String validUntilIso;
  SyncStatus syncStatus;
  int retryCount;

  OfflineGatePass({
    required this.passCode,
    required this.leaseId,
    required this.idempotencyKey,
    required this.qrSignature,
    required this.facilityName,
    required this.dockGate,
    this.driverName,
    this.driverLicense,
    this.vehiclePlate,
    required this.validUntilIso,
    this.syncStatus = SyncStatus.pending,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() => {
        'passCode': passCode,
        'leaseId': leaseId,
        'idempotencyKey': idempotencyKey,
        'qrSignature': qrSignature,
        'facilityName': facilityName,
        'dockGate': dockGate,
        'driverName': driverName,
        'driverLicense': driverLicense,
        'vehiclePlate': vehiclePlate,
        'validUntilIso': validUntilIso,
        'syncStatus': syncStatus.name,
        'retryCount': retryCount,
      };

  factory OfflineGatePass.fromMap(Map<String, dynamic> map) => OfflineGatePass(
        passCode: map['passCode'] as String,
        leaseId: map['leaseId'] as String,
        idempotencyKey: map['idempotencyKey'] as String,
        qrSignature: map['qrSignature'] as String,
        facilityName: map['facilityName'] as String,
        dockGate: map['dockGate'] as String,
        driverName: map['driverName'] as String?,
        driverLicense: map['driverLicense'] as String?,
        vehiclePlate: map['vehiclePlate'] as String?,
        validUntilIso: map['validUntilIso'] as String,
        syncStatus: SyncStatus.values.byName(map['syncStatus'] ?? 'pending'),
        retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      );

  String toJson() => jsonEncode(toMap());
  factory OfflineGatePass.fromJson(String source) =>
      OfflineGatePass.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
