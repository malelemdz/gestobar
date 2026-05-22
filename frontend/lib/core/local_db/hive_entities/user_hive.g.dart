// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserHiveAdapter extends TypeAdapter<UserHive> {
  @override
  final int typeId = 5;

  @override
  UserHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserHive(
      id: fields[0] as String,
      username: fields[1] as String,
      nombre: fields[2] as String,
      rolId: fields[3] as String,
      rolNombre: fields[4] as String,
      barId: fields[5] as String?,
      fotoUrl: fields[6] as String?,
      celular: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.nombre)
      ..writeByte(3)
      ..write(obj.rolId)
      ..writeByte(4)
      ..write(obj.rolNombre)
      ..writeByte(5)
      ..write(obj.barId)
      ..writeByte(6)
      ..write(obj.fotoUrl)
      ..writeByte(7)
      ..write(obj.celular);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
