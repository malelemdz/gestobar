class VariantModel {
  final String id;
  final String nombre;
  final double precioA;
  final double precioB;
  final bool disponible;

  VariantModel({
    required this.id,
    required this.nombre,
    required this.precioA,
    required this.precioB,
    required this.disponible,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      precioA: (json['precio_a'] is num)
          ? (json['precio_a'] as num).toDouble()
          : double.tryParse(json['precio_a']?.toString() ?? '') ?? 0.0,
      precioB: (json['precio_b'] is num)
          ? (json['precio_b'] as num).toDouble()
          : double.tryParse(json['precio_b']?.toString() ?? '') ?? 0.0,
      disponible: json['disponible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio_a': precioA,
      'precio_b': precioB,
      'disponible': disponible,
    };
  }
}
