class CategoryModel {
  final String id;
  final String nombre;
  final int orden;

  CategoryModel({
    required this.id,
    required this.nombre,
    required this.orden,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      orden: json['orden'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'orden': orden,
    };
  }
}
