class AuditoriaModel {
  final String id;
  final String barId;
  final String usuarioId;
  final String? usuarioNombre;
  final String rolNombre;
  final String accion;
  final String modulo;
  final Map<String, dynamic>? detalles;
  final String? ipAddress;
  final String? dispositivo;
  final DateTime fecha;

  AuditoriaModel({
    required this.id,
    required this.barId,
    required this.usuarioId,
    this.usuarioNombre,
    required this.rolNombre,
    required this.accion,
    required this.modulo,
    this.detalles,
    this.ipAddress,
    this.dispositivo,
    required this.fecha,
  });

  factory AuditoriaModel.fromJson(Map<String, dynamic> json) {
    return AuditoriaModel(
      id: json['id'] ?? '',
      barId: json['bar_id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      usuarioNombre: json['usuario']?['nombre'],
      rolNombre: json['rol_nombre'] ?? '',
      accion: json['accion'] ?? '',
      modulo: json['modulo'] ?? '',
      detalles: json['detalles'],
      ipAddress: json['ip_address'],
      dispositivo: json['dispositivo'],
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
    );
  }
}
