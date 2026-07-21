import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'offline_transaction.dart';
import '../../features/inventory/data/models/inventory_dto.dart';

class IsarDatabase {
  static IsarDatabase? _instance;
  late final Isar _isar;

  IsarDatabase._(this._isar);

  Isar get isar => _isar;

  static IsarDatabase get instance {
    if (_instance == null) {
      throw Exception('IsarDatabase has not been initialized. Call init() first.');
    }
    return _instance!;
  }

  static Future<void> init({List<int>? encryptionKey}) async {
    if (_instance != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final isarInstance = await Isar.open(
      [
        OfflineTransactionSchema,
        InventoryDtoSchema,
      ],
      directory: dir.path,
      name: 'antigravity_local_db',
    );

    _instance = IsarDatabase._(isarInstance);
  }
}
