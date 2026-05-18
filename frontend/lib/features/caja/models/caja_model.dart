import '../../../features/auth/models/user_model.dart';

class CajaModel {
  final String id;
  final String barId;
  final String aperturaUsuarioId;
  final String? cierreUsuarioId;
  final double montoInicial;
  final double? montoFinal;
  final String estado; // 'ABIERTA' | 'CERRADA'
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final UserModel? aperturaUsuario;
  final UserModel? cierreUsuario;

  CajaModel({
    required this.id,
    required this.barId,
    required this.aperturaUsuarioId,
    this.cierreUsuarioId,
    required this.montoInicial,
    this.montoFinal,
    required this.estado,
    required this.fechaApertura,
    this.fechaCierre,
    this.aperturaUsuario,
    this.cierreUsuario,
  });

  factory CajaModel.fromJson(Map<String, dynamic> json) {
    return CajaModel(
      id: json['id'] as String? ?? '',
      barId: json['bar_id'] as String? ?? '',
      aperturaUsuarioId: json['apertura_usuario_id'] as String? ?? '',
      cierreUsuarioId: json['cierre_usuario_id'] as String?,
      montoInicial: (json['monto_inicial'] is num)
          ? (json['monto_inicial'] as num).toDouble()
          : double.tryParse(json['monto_inicial']?.toString() ?? '') ?? 0.0,
      montoFinal: json['monto_final'] != null
          ? ((json['monto_final'] is num)
              ? (json['monto_final'] as num).toDouble()
              : double.tryParse(json['monto_final'].toString()) ?? 0.0)
          : null,
      estado: json['estado'] as String? ?? 'CERRADA',
      fechaApertura: json['fecha_apertura'] != null
          ? DateTime.parse(json['fecha_apertura'] as String)
          : DateTime.now(),
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.parse(json['fecha_cierre'] as String)
          : null,
      aperturaUsuario: json['aperturaUsuario'] != null
          ? UserModel.fromJson(json['aperturaUsuario'] as Map<String, dynamic>)
          : null,
      cierreUsuario: json['cierreUsuario'] != null
          ? UserModel.fromJson(json['cierreUsuario'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bar_id': barId,
      'apertura_usuario_id': aperturaUsuarioId,
      'cierre_usuario_id': cierreUsuarioId,
      'monto_inicial': montoInicial,
      'monto_final': montoFinal,
      'estado': estado,
      'fecha_apertura': fechaApertura.toIso8601String(),
      'fecha_cierre': fechaCierre?.toIso8601String(),
    };
  }
}

class EstadoCajaResponse {
  final bool abierta;
  final CajaModel? caja;

  EstadoCajaResponse({
    required this.abierta,
    this.caja,
  });

  factory EstadoCajaResponse.fromJson(Map<String, dynamic> json) {
    return EstadoCajaResponse(
      abierta: json['abierta'] as bool? ?? false,
      caja: json['caja'] != null
          ? CajaModel.fromJson(json['caja'] as Map<String, dynamic>)
          : null,
    );
  }
}
