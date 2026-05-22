import '../../../features/pos/models/category_model.dart';
import '../../../features/pos/models/product_model.dart';
import '../../../features/pos/models/variant_model.dart';
import '../../../features/pos/models/variant_price_model.dart';

import '../hive_entities/category_hive.dart';
import '../hive_entities/product_hive.dart';

// Mappers for Category
extension CategoryMapper on CategoryModel {
  CategoryHive toHive() {
    return CategoryHive()
      ..id = id
      ..nombre = nombre
      ..orden = orden
      ..disponible = disponible;
  }
}

extension CategoryHiveMapper on CategoryHive {
  CategoryModel toDomain() {
    return CategoryModel(
      id: id,
      nombre: nombre,
      orden: orden,
      disponible: disponible,
    );
  }
}

// Mappers for Product
extension ProductMapper on ProductModel {
  ProductHive toHive() {
    return ProductHive()
      ..id = id
      ..nombre = nombre
      ..descripcion = descripcion
      ..fotoUrl = fotoUrl
      ..categoriaId = categoriaId
      ..disponible = disponible
      ..variantes = variantes.map((v) => v.toHive()).toList();
  }
}

extension ProductHiveMapper on ProductHive {
  ProductModel toDomain() {
    return ProductModel(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      fotoUrl: fotoUrl,
      categoriaId: categoriaId,
      disponible: disponible,
      variantes: variantes.map((v) => v.toDomain()).toList(),
    );
  }
}

extension VariantMapper on VariantModel {
  VariantHive toHive() {
    return VariantHive()
      ..id = id
      ..nombre = nombre
      ..precioA = precioA
      ..precioB = precioB
      ..disponible = disponible
      ..precios = precios.map((p) => p.toHive()).toList();
  }
}

extension VariantHiveMapper on VariantHive {
  VariantModel toDomain() {
    return VariantModel(
      id: id,
      nombre: nombre,
      precioA: precioA,
      precioB: precioB,
      disponible: disponible,
      precios: precios.map((p) => p.toDomain()).toList(),
    );
  }
}

extension VariantPriceMapper on VariantPriceModel {
  VariantPriceHive toHive() {
    return VariantPriceHive()
      ..id = id
      ..tarifaId = tarifaId
      ..precioUnitario = precioUnitario
      ..tarifaNombre = tarifaNombre
      ..esDefault = esDefault;
  }
}

extension VariantPriceHiveMapper on VariantPriceHive {
  VariantPriceModel toDomain() {
    return VariantPriceModel(
      id: id,
      tarifaId: tarifaId,
      precioUnitario: precioUnitario,
      tarifaNombre: tarifaNombre,
      esDefault: esDefault,
    );
  }
}
