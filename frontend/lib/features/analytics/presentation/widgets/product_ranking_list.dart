import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/core/widgets/shimmer_placeholder.dart';
import '../../providers/analytics_provider.dart';
import '../../data/models/product_ranking_model.dart';

class ProductRankingList extends ConsumerWidget {
  const ProductRankingList({super.key});

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Oro
      case 2:
        return const Color(0xFFE0E0E0); // Plata
      case 3:
        return const Color(0xFFCD7F32); // Bronce
      default:
        return const Color(0xFF00F0FF); // Cyan
    }
  }

  Widget _buildProductAvatar(String? fotoUrl, double size) {
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Image.network(
          fotoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackAvatar(size),
        ),
      );
    }
    return _buildFallbackAvatar(size);
  }

  Widget _buildFallbackAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Center(
        child: Icon(Icons.local_bar_rounded, size: 18, color: Color(0xFF00F0FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(analyticsProductRankingProvider);

    return rankingAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ShimmerPlaceholder(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error al cargar ranking: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024),
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64.0, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 16.0),
                Text(
                  'No hay ventas registradas',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final int maxQuantity = products.first.cantidadVendida;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final p = products[index];
            final rank = index + 1;
            final rankColor = _getRankColor(rank);
            final double sharePercent = maxQuantity == 0 ? 0.0 : (p.cantidadVendida / maxQuantity);

            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2024),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Posición del Ranking
                      Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: rankColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: rankColor.withOpacity(0.3), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '$rank',
                            style: GoogleFonts.plusJakartaSans(
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),

                      // Foto del Producto
                      _buildProductAvatar(p.fotoUrl, 44.0),
                      const SizedBox(width: 14.0),

                      // Nombre del Producto y Categoría
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.productoNombre,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '${p.varianteNombre} • ${p.categoria}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11.0,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12.0),

                      // Métricas (Cantidad e Ingresos)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${p.cantidadVendida} unid.',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${p.totalRecaudado.toStringAsFixed(2)} Bs',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00F0FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Barra de Proporción Relativa al Producto #1
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Container(
                      height: 5.0,
                      color: Colors.white.withOpacity(0.02),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: sharePercent.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                rankColor.withOpacity(0.4),
                                rankColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
