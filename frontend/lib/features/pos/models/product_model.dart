import 'variant_model.dart';

class ProductModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final String? fotoUrl;
  final String categoriaId;
  final bool disponible;
  final List<VariantModel> variantes;

  ProductModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.fotoUrl,
    required this.categoriaId,
    this.disponible = true,
    required this.variantes,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    var list = json['variantes'] as List? ?? [];
    List<VariantModel> variantsList =
        list.map((i) => VariantModel.fromJson(i as Map<String, dynamic>)).toList();

    return ProductModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      fotoUrl: json['foto_url'] as String?,
      categoriaId: json['categoria_id'] as String? ?? '',
      disponible: json['disponible'] as bool? ?? true,
      variantes: variantsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
      'categoria_id': categoriaId,
      'disponible': disponible,
      'variantes': variantes.map((v) => v.toJson()).toList(),
    };
  }
}
