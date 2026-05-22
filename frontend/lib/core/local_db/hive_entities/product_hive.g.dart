// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductHiveAdapter extends TypeAdapter<ProductHive> {
  @override
  final int typeId = 1;

  @override
  ProductHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductHive()
      ..id = fields[0] as String
      ..nombre = fields[1] as String
      ..descripcion = fields[2] as String?
      ..fotoUrl = fields[3] as String?
      ..categoriaId = fields[4] as String
      ..disponible = fields[5] as bool
      ..variantes = (fields[6] as List).cast<VariantHive>();
  }

  @override
  void write(BinaryWriter writer, ProductHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.fotoUrl)
      ..writeByte(4)
      ..write(obj.categoriaId)
      ..writeByte(5)
      ..write(obj.disponible)
      ..writeByte(6)
      ..write(obj.variantes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VariantHiveAdapter extends TypeAdapter<VariantHive> {
  @override
  final int typeId = 2;

  @override
  VariantHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VariantHive()
      ..id = fields[0] as String
      ..nombre = fields[1] as String
      ..precioA = fields[2] as double
      ..precioB = fields[3] as double
      ..disponible = fields[4] as bool
      ..precios = (fields[5] as List).cast<VariantPriceHive>();
  }

  @override
  void write(BinaryWriter writer, VariantHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.precioA)
      ..writeByte(3)
      ..write(obj.precioB)
      ..writeByte(4)
      ..write(obj.disponible)
      ..writeByte(5)
      ..write(obj.precios);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VariantPriceHiveAdapter extends TypeAdapter<VariantPriceHive> {
  @override
  final int typeId = 3;

  @override
  VariantPriceHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VariantPriceHive()
      ..id = fields[0] as String
      ..tarifaId = fields[1] as String
      ..precioUnitario = fields[2] as double
      ..tarifaNombre = fields[3] as String
      ..esDefault = fields[4] as bool;
  }

  @override
  void write(BinaryWriter writer, VariantPriceHive obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tarifaId)
      ..writeByte(2)
      ..write(obj.precioUnitario)
      ..writeByte(3)
      ..write(obj.tarifaNombre)
      ..writeByte(4)
      ..write(obj.esDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantPriceHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
