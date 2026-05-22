class TarifaModel {
  final String id;
  final String barId;
  final String nombre;
  final bool esDefault;
  final bool activo;

  TarifaModel({
    required this.id,
    required this.barId,
    required this.nombre,
    required this.esDefault,
    required this.activo,
  });

  factory TarifaModel.fromJson(Map<String, dynamic> json) {
    return TarifaModel(
      id: json['id'] as String,
      barId: json['bar_id'] as String,
      nombre: json['nombre'] as String,
      esDefault: json['es_default'] as bool? ?? false,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bar_id': barId,
      'nombre': nombre,
      'es_default': esDefault,
      'activo': activo,
    };
  }
}
