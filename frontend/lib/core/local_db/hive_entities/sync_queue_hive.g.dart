// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncQueueTaskHiveAdapter extends TypeAdapter<SyncQueueTaskHive> {
  @override
  final int typeId = 4;

  @override
  SyncQueueTaskHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueTaskHive()
      ..method = fields[0] as String
      ..endpoint = fields[1] as String
      ..payload = fields[2] as String
      ..createdAt = fields[3] as DateTime
      ..retries = fields[4] as int;
  }

  @override
  void write(BinaryWriter writer, SyncQueueTaskHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.method)
      ..writeByte(1)
      ..write(obj.endpoint)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.retries);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueTaskHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
