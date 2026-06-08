class AnalyticsResumenModel {
  final DateTime inicio;
  final DateTime fin;
  final double ingresosTotales;
  final double comisionesPagadas;
  final double ingresoNetoEstimado;
  final int cantidadVentas;
  final List<PaymentMethodBreakdown> desglosePagos;
  final List<DailySalesModel> ventasDiarias;

  AnalyticsResumenModel({
    required this.inicio,
    required this.fin,
    required this.ingresosTotales,
    required this.comisionesPagadas,
    required this.ingresoNetoEstimado,
    required this.cantidadVentas,
    required this.desglosePagos,
    required this.ventasDiarias,
  });

  factory AnalyticsResumenModel.fromJson(Map<String, dynamic> json) {
    final rango = json['rango'] as Map<String, dynamic>? ?? {};
    final pagos = json['desglose_pagos'] as List? ?? [];
    final diarias = json['ventas_diarias'] as List? ?? [];

    return AnalyticsResumenModel(
      inicio: rango['inicio'] != null ? DateTime.parse(rango['inicio']) : DateTime.now(),
      fin: rango['fin'] != null ? DateTime.parse(rango['fin']) : DateTime.now(),
      ingresosTotales: (json['ingresos_totales'] ?? 0.0).toDouble(),
      comisionesPagadas: (json['comisiones_pagadas'] ?? 0.0).toDouble(),
      ingresoNetoEstimado: (json['ingreso_neto_estimado'] ?? 0.0).toDouble(),
      cantidadVentas: json['cantidad_ventas'] ?? 0,
      desglosePagos: pagos.map((e) => PaymentMethodBreakdown.fromJson(e as Map<String, dynamic>)).toList(),
      ventasDiarias: diarias.map((e) => DailySalesModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class PaymentMethodBreakdown {
  final String metodo;
  final double total;
  final int cantidad;

  PaymentMethodBreakdown({
    required this.metodo,
    required this.total,
    required this.cantidad,
  });

  factory PaymentMethodBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentMethodBreakdown(
      metodo: json['metodo'] ?? 'Otros',
      total: (json['total'] ?? 0.0).toDouble(),
      cantidad: json['cantidad'] ?? 0,
    );
  }
}

class DailySalesModel {
  final String fecha; // YYYY-MM-DD
  final double total;
  final int cantidad;

  DailySalesModel({
    required this.fecha,
    required this.total,
    required this.cantidad,
  });

  factory DailySalesModel.fromJson(Map<String, dynamic> json) {
    return DailySalesModel(
      fecha: json['fecha'] ?? '',
      total: (json['total'] ?? 0.0).toDouble(),
      cantidad: json['cantidad'] ?? 0,
    );
  }
}
