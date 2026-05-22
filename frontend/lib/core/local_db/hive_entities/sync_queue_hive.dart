import 'package:hive/hive.dart';

part 'sync_queue_hive.g.dart';

@HiveType(typeId: 4)
class SyncQueueTaskHive extends HiveObject {
  @HiveField(0)
  late String method;

  @HiveField(1)
  late String endpoint;

  @HiveField(2)
  late String payload;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late int retries;
}
