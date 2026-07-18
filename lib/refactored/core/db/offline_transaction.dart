import 'package:isar/isar.dart';

part 'offline_transaction.g.dart';

@collection
class OfflineTransaction {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String idempotencyKey;

  late String actionType;
  late String payloadJson;
  late DateTime timestamp;
}
