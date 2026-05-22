import 'package:isar/isar.dart';

part 'sync_queue_entity.g.dart';

@collection
class SyncQueueTaskIsar {
  Id id = Isar.autoIncrement;

  late String method; // POST, PATCH, DELETE
  late String endpoint; // e.g., '/orders'
  late String payload; // JSON string of the body
  
  late DateTime createdAt;
  late int retries; // Number of failed sync attempts
}
