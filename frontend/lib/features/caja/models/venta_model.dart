import '../../../features/auth/models/user_model.dart';
import '../../../features/pos/models/variant_model.dart';
import '../../../core/utils/timezone_helper.dart';

class VentaModel {
  final String id;
  final String barId;
  final String cajaId;
  final String usuarioId;
  final double total;
  final String metodoPago;
  final double montoEfectivo;
  final double montoTarjeta;
  final double montoTrQr;
  final DateTime fecha;
  final UserModel? usuario;
  final List<DetalleVentaModel> detalles;

  VentaModel({
    required this.id,
    required this.barId,
    required this.cajaId,
    required this.usuarioId,
    required this.total,
    required this.metodoPago,
    required this.montoEfectivo,
    required this.montoTarjeta,
    required this.montoTrQr,
    required this.fecha,
    this.usuario,
    required this.detalles,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    return VentaModel(
      id: json['id'] as String? ?? '',
      barId: json['bar_id'] as String? ?? '',
      cajaId: json['caja_id'] as String? ?? '',
      usuarioId: json['usuario_id'] as String? ?? '',
      total: (json['total'] is num)
          ? (json['total'] as num).toDouble()
          : double.tryParse(json['total']?.toString() ?? '') ?? 0.0,
      metodoPago: json['metodo_pago'] as String? ?? '',
      montoEfectivo: (json['monto_efectivo'] is num)
          ? (json['monto_efectivo'] as num).toDouble()
          : double.tryParse(json['monto_efectivo']?.toString() ?? '') ?? 0.0,
      montoTarjeta: (json['monto_tarjeta'] is num)
          ? (json['monto_tarjeta'] as num).toDouble()
          : double.tryParse(json['monto_tarjeta']?.toString() ?? '') ?? 0.0,
      montoTrQr: (json['monto_tr_qr'] is num)
          ? (json['monto_tr_qr'] as num).toDouble()
          : double.tryParse(json['monto_tr_qr']?.toString() ?? '') ?? 0.0,
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'] as String)
          : TimezoneHelper.now,
      usuario: json['usuario'] != null
          ? UserModel.fromJson(json['usuario'] as Map<String, dynamic>)
          : null,
      detalles: (json['detalles'] as List<dynamic>?)
              ?.map((e) => DetalleVentaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DetalleVentaModel {
  final String id;
  final String varianteId;
  final int cantidad;
  final double precioUnitario;
  final bool esPrecioB;
  final String? damaId;
  final double comisionDama;
  final bool esInvitacion;
  final VariantModel? variante;
  final UserModel? dama;
  final String productoNombre;

  DetalleVentaModel({
    required this.id,
    required this.varianteId,
    required this.cantidad,
    required this.precioUnitario,
    required this.esPrecioB,
    this.damaId,
    required this.comisionDama,
    required this.esInvitacion,
    this.variante,
    this.dama,
    required this.productoNombre,
  });

  factory DetalleVentaModel.fromJson(Map<String, dynamic> json) {
    String pNombre = 'Producto';
    if (json['variante'] != null && json['variante']['producto'] != null) {
      pNombre = json['variante']['producto']['nombre'] as String? ?? 'Producto';
    }

    return DetalleVentaModel(
      id: json['id'] as String? ?? '',
      varianteId: json['variante_id'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 1,
      precioUnitario: (json['precio_unitario'] is num)
          ? (json['precio_unitario'] as num).toDouble()
          : double.tryParse(json['precio_unitario']?.toString() ?? '') ?? 0.0,
      esPrecioB: json['es_precio_b'] as bool? ?? false,
      damaId: json['dama_id'] as String?,
      comisionDama: (json['comision_dama'] is num)
          ? (json['comision_dama'] as num).toDouble()
          : double.tryParse(json['comision_dama']?.toString() ?? '') ?? 0.0,
      esInvitacion: json['es_invitacion'] as bool? ?? false,
      variante: json['variante'] != null
          ? VariantModel.fromJson(json['variante'] as Map<String, dynamic>)
          : null,
      dama: json['dama'] != null
          ? UserModel.fromJson(json['dama'] as Map<String, dynamic>)
          : null,
      productoNombre: pNombre,
    );
  }
}
