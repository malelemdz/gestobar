class EventoMovimiento {
  final String id;
  final String tipo; // 'VENTA', 'INGRESO', 'EGRESO'
  final DateTime fecha;
  final double monto;
  final String metodoPago;
  final String concepto;
  final String cajero;
  final dynamic original; // CajaMovimientoModel o VentaModel

  EventoMovimiento({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.monto,
    required this.metodoPago,
    required this.concepto,
    required this.cajero,
    required this.original,
  });
}
