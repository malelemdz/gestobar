import 'variant_price_model.dart';

class VariantModel {
  final String id;
  final String nombre;
  final double precioA;
  final double precioB;
  final bool disponible;
  final List<VariantPriceModel> precios;

  VariantModel({
    required this.id,
    required this.nombre,
    required this.precioA,
    required this.precioB,
    required this.disponible,
    required this.precios,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    final rawPrecios = json['precios'] as List? ?? [];
    final List<VariantPriceModel> preciosList = rawPrecios
        .map((p) => VariantPriceModel.fromJson(p as Map<String, dynamic>))
        .toList();

    // Buscar precio general (tarifa default)
    final defaultPriceObj = preciosList.firstWhere(
      (p) => p.esDefault,
      orElse: () => preciosList.isNotEmpty 
          ? preciosList.first 
          : VariantPriceModel(id: '', tarifaId: '', precioUnitario: 0.0, tarifaNombre: '', esDefault: false),
    );

    // Buscar precio compañía (tarifa no default)
    final companyPriceObj = preciosList.firstWhere(
      (p) => !p.esDefault,
      orElse: () => preciosList.length > 1 ? preciosList[1] : defaultPriceObj,
    );

    // Permitir fallback de campos tradicionales precio_a/precio_b si vienen del backend directos
    final double parsedPrecioA = json['precio_a'] != null
        ? ((json['precio_a'] is num) ? (json['precio_a'] as num).toDouble() : double.tryParse(json['precio_a'].toString()) ?? 0.0)
        : defaultPriceObj.precioUnitario;

    final double parsedPrecioB = json['precio_b'] != null
        ? ((json['precio_b'] is num) ? (json['precio_b'] as num).toDouble() : double.tryParse(json['precio_b'].toString()) ?? 0.0)
        : companyPriceObj.precioUnitario;

    return VariantModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      precioA: parsedPrecioA,
      precioB: parsedPrecioB,
      disponible: json['disponible'] as bool? ?? true,
      precios: preciosList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio_a': precioA,
      'precio_b': precioB,
      'disponible': disponible,
      'precios': precios.map((p) => p.toJson()).toList(),
    };
  }
}
