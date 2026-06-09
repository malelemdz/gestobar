import '../../../features/auth/models/user_model.dart';
import '../../../core/utils/timezone_helper.dart';

class CajaMovimientoModel {
  final String id;
  final String cajaId;
  final double monto;
  final String tipo; // 'INGRESO' | 'EGRESO'
  final String metodoPago; // 'EFECTIVO' | 'TARJETA' | 'TRANSFERENCIA'
  final String concepto;
  final String usuarioId;
  final UserModel? usuario;
  final DateTime createdAt;

  CajaMovimientoModel({
    required this.id,
    required this.cajaId,
    required this.monto,
    required this.tipo,
    required this.metodoPago,
    required this.concepto,
    required this.usuarioId,
    this.usuario,
    required this.createdAt,
  });

  factory CajaMovimientoModel.fromJson(Map<String, dynamic> json) {
    return CajaMovimientoModel(
      id: json['id'] as String? ?? '',
      cajaId: json['caja_id'] as String? ?? '',
      monto: (json['monto'] is num)
          ? (json['monto'] as num).toDouble()
          : double.tryParse(json['monto']?.toString() ?? '') ?? 0.0,
      tipo: json['tipo'] as String? ?? 'INGRESO',
      metodoPago: json['metodo_pago'] as String? ?? 'EFECTIVO',
      concepto: json['concepto'] as String? ?? '',
      usuarioId: json['usuario_id'] as String? ?? '',
      usuario: json['usuario'] != null
          ? UserModel.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : TimezoneHelper.now,
    );
  }
}

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

  // Nuevas Métricas Financieras Enriquecidas
  final double totalVentasEfectivo;
  final double totalVentasTarjeta;
  final double totalVentasTrQr;
  final double totalIngresosManuales;
  final double totalEgresosManuales;
  final double totalComisionesDamas;
  final double totalEsperadoGaveta;
  final double gananciaNetaBar;
  final List<CajaMovimientoModel> movimientos;

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
    this.totalVentasEfectivo = 0.0,
    this.totalVentasTarjeta = 0.0,
    this.totalVentasTrQr = 0.0,
    this.totalIngresosManuales = 0.0,
    this.totalEgresosManuales = 0.0,
    this.totalComisionesDamas = 0.0,
    this.totalEsperadoGaveta = 0.0,
    this.gananciaNetaBar = 0.0,
    this.movimientos = const [],
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
          : TimezoneHelper.now,
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.parse(json['fecha_cierre'] as String)
          : null,
      aperturaUsuario: json['aperturaUsuario'] != null
          ? UserModel.fromJson(json['aperturaUsuario'] as Map<String, dynamic>)
          : null,
      cierreUsuario: json['cierreUsuario'] != null
          ? UserModel.fromJson(json['cierreUsuario'] as Map<String, dynamic>)
          : null,
      totalVentasEfectivo: (json['total_ventas_efectivo'] is num)
          ? (json['total_ventas_efectivo'] as num).toDouble()
          : double.tryParse(json['total_ventas_efectivo']?.toString() ?? '') ?? 0.0,
      totalVentasTarjeta: (json['total_ventas_tarjeta'] is num)
          ? (json['total_ventas_tarjeta'] as num).toDouble()
          : double.tryParse(json['total_ventas_tarjeta']?.toString() ?? '') ?? 0.0,
      totalVentasTrQr: (json['total_ventas_tr_qr'] is num)
          ? (json['total_ventas_tr_qr'] as num).toDouble()
          : double.tryParse(json['total_ventas_tr_qr']?.toString() ?? '') ?? 0.0,
      totalIngresosManuales: (json['total_ingresos_manuales'] is num)
          ? (json['total_ingresos_manuales'] as num).toDouble()
          : double.tryParse(json['total_ingresos_manuales']?.toString() ?? '') ?? 0.0,
      totalEgresosManuales: (json['total_egresos_manuales'] is num)
          ? (json['total_egresos_manuales'] as num).toDouble()
          : double.tryParse(json['total_egresos_manuales']?.toString() ?? '') ?? 0.0,
      totalComisionesDamas: (json['total_comisiones_damas'] is num)
          ? (json['total_comisiones_damas'] as num).toDouble()
          : double.tryParse(json['total_comisiones_damas']?.toString() ?? '') ?? 0.0,
      totalEsperadoGaveta: (json['total_esperado_gaveta'] is num)
          ? (json['total_esperado_gaveta'] as num).toDouble()
          : double.tryParse(json['total_esperado_gaveta']?.toString() ?? '') ?? 0.0,
      gananciaNetaBar: (json['ganancia_neta_bar'] is num)
          ? (json['ganancia_neta_bar'] as num).toDouble()
          : double.tryParse(json['ganancia_neta_bar']?.toString() ?? '') ?? 0.0,
      movimientos: (json['movimientos'] as List<dynamic>?)
              ?.map((e) => CajaMovimientoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
