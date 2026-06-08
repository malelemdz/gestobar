class ProductRankingModel {
  final String varianteId;
  final String varianteNombre;
  final String productoNombre;
  final String? fotoUrl;
  final String categoria;
  final int cantidadVendida;
  final double totalRecaudado;

  ProductRankingModel({
    required this.varianteId,
    required this.varianteNombre,
    required this.productoNombre,
    this.fotoUrl,
    required this.categoria,
    required this.cantidadVendida,
    required this.totalRecaudado,
  });

  factory ProductRankingModel.fromJson(Map<String, dynamic> json) {
    return ProductRankingModel(
      varianteId: json['variante_id'] ?? '',
      varianteNombre: json['variante_nombre'] ?? '',
      productoNombre: json['producto_nombre'] ?? '',
      fotoUrl: json['foto_url'],
      categoria: json['categoria'] ?? 'Sin categoría',
      cantidadVendida: json['cantidad_vendida'] ?? 0,
      totalRecaudado: (json['total_recaudado'] ?? 0.0).toDouble(),
    );
  }
}
