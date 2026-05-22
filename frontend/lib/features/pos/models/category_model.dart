class CategoryModel {
  final String id;
  final String nombre;
  final int orden;
  final bool disponible;

  CategoryModel({
    required this.id,
    required this.nombre,
    required this.orden,
    this.disponible = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      orden: json['orden'] as int? ?? 0,
      disponible: json['disponible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'orden': orden,
      'disponible': disponible,
    };
  }
}
