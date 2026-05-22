class VariantPriceModel {
  final String id;
  final String tarifaId;
  final double precioUnitario;
  final String tarifaNombre;
  final bool esDefault;

  VariantPriceModel({
    required this.id,
    required this.tarifaId,
    required this.precioUnitario,
    required this.tarifaNombre,
    required this.esDefault,
  });

  factory VariantPriceModel.fromJson(Map<String, dynamic> json) {
    final tarifa = json['tarifa'] as Map<String, dynamic>?;
    return VariantPriceModel(
      id: json['id'] as String? ?? '',
      tarifaId: json['tarifa_id'] as String? ?? '',
      precioUnitario: (json['precio_unitario'] is num)
          ? (json['precio_unitario'] as num).toDouble()
          : double.tryParse(json['precio_unitario']?.toString() ?? '') ?? 0.0,
      tarifaNombre: tarifa?['nombre'] as String? ?? '',
      esDefault: tarifa?['es_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tarifa_id': tarifaId,
      'precio_unitario': precioUnitario,
      'tarifa': {
        'nombre': tarifaNombre,
        'es_default': esDefault,
      },
    };
  }
}
