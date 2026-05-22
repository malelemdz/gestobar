import 'package:hive/hive.dart';

part 'product_hive.g.dart';

@HiveType(typeId: 1)
class ProductHive extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String nombre;

  @HiveField(2)
  String? descripcion;

  @HiveField(3)
  String? fotoUrl;

  @HiveField(4)
  late String categoriaId;

  @HiveField(5)
  late bool disponible;

  @HiveField(6)
  late List<VariantHive> variantes;
}

@HiveType(typeId: 2)
class VariantHive extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String nombre;

  @HiveField(2)
  late double precioA;

  @HiveField(3)
  late double precioB;

  @HiveField(4)
  late bool disponible;

  @HiveField(5)
  late List<VariantPriceHive> precios;
}

@HiveType(typeId: 3)
class VariantPriceHive extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String tarifaId;

  @HiveField(2)
  late double precioUnitario;

  @HiveField(3)
  late String tarifaNombre;

  @HiveField(4)
  late bool esDefault;
}
