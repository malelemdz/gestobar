import 'package:isar/isar.dart';

part 'product_entity.g.dart';

@collection
class ProductIsar {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String backendId;

  late String nombre;
  String? descripcion;
  String? fotoUrl;

  @Index()
  late String categoriaId;

  late bool disponible;

  late List<VariantIsar> variantes;
}

@embedded
class VariantIsar {
  String? backendId;
  String? nombre;
  double? precioA;
  double? precioB;
  bool? disponible;
  
  List<VariantPriceIsar>? precios;
}

@embedded
class VariantPriceIsar {
  String? backendId;
  String? tarifaId;
  double? precioUnitario;
  String? tarifaNombre;
  bool? esDefault;
}
