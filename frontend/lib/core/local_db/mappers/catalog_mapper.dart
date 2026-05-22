import '../../../features/pos/models/category_model.dart';
import '../../../features/pos/models/product_model.dart';
import '../../../features/pos/models/variant_model.dart';
import '../../../features/pos/models/variant_price_model.dart';

import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

// Mappers for Category
extension CategoryMapper on CategoryModel {
  CategoryIsar toIsar() {
    return CategoryIsar()
      ..backendId = id
      ..nombre = nombre
      ..orden = orden
      ..disponible = disponible;
  }
}

extension CategoryIsarMapper on CategoryIsar {
  CategoryModel toDomain() {
    return CategoryModel(
      id: backendId,
      nombre: nombre,
      orden: orden,
      disponible: disponible,
    );
  }
}

// Mappers for Product
extension ProductMapper on ProductModel {
  ProductIsar toIsar() {
    return ProductIsar()
      ..backendId = id
      ..nombre = nombre
      ..descripcion = descripcion
      ..fotoUrl = fotoUrl
      ..categoriaId = categoriaId
      ..disponible = disponible
      ..variantes = variantes.map((v) => v.toIsar()).toList();
  }
}

extension ProductIsarMapper on ProductIsar {
  ProductModel toDomain() {
    return ProductModel(
      id: backendId,
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
  VariantIsar toIsar() {
    return VariantIsar()
      ..backendId = id
      ..nombre = nombre
      ..precioA = precioA
      ..precioB = precioB
      ..disponible = disponible
      ..precios = precios.map((p) => p.toIsar()).toList();
  }
}

extension VariantIsarMapper on VariantIsar {
  VariantModel toDomain() {
    return VariantModel(
      id: backendId ?? '',
      nombre: nombre ?? '',
      precioA: precioA ?? 0.0,
      precioB: precioB ?? 0.0,
      disponible: disponible ?? true,
      precios: precios?.map((p) => p.toDomain()).toList() ?? [],
    );
  }
}

extension VariantPriceMapper on VariantPriceModel {
  VariantPriceIsar toIsar() {
    return VariantPriceIsar()
      ..backendId = id
      ..tarifaId = tarifaId
      ..precioUnitario = precioUnitario
      ..tarifaNombre = tarifaNombre
      ..esDefault = esDefault;
  }
}

extension VariantPriceIsarMapper on VariantPriceIsar {
  VariantPriceModel toDomain() {
    return VariantPriceModel(
      id: backendId ?? '',
      tarifaId: tarifaId ?? '',
      precioUnitario: precioUnitario ?? 0.0,
      tarifaNombre: tarifaNombre ?? '',
      esDefault: esDefault ?? false,
    );
  }
}
