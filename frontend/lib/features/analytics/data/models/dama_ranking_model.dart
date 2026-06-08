class DamaRankingModel {
  final String damaId;
  final String nombre;
  final String email;
  final double comisionesAcumuladas;
  final int invitacionesRecibidas;
  final int turnosCompania;

  DamaRankingModel({
    required this.damaId,
    required this.nombre,
    required this.email,
    required this.comisionesAcumuladas,
    required this.invitacionesRecibidas,
    required this.turnosCompania,
  });

  factory DamaRankingModel.fromJson(Map<String, dynamic> json) {
    return DamaRankingModel(
      damaId: json['dama_id'] ?? '',
      nombre: json['nombre'] ?? 'Sin nombre',
      email: json['email'] ?? '',
      comisionesAcumuladas: (json['comisiones_acumuladas'] ?? 0.0).toDouble(),
      invitacionesRecibidas: json['invitaciones_recibidas'] ?? 0,
      turnosCompania: json['turnos_compania'] ?? 0,
    );
  }
}
