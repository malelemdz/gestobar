import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/core/widgets/shimmer_placeholder.dart';
import 'package:gestobar/core/utils/currency_helper.dart';
import '../../../caja/providers/caja_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../data/models/dama_ranking_model.dart';

class DamaRankingList extends ConsumerWidget {
  const DamaRankingList({super.key});

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFF4081); // Rosa Brillante (Top 1)
      case 2:
        return const Color(0xFFE040FB); // Violeta
      case 3:
        return const Color(0xFF00F0FF); // Cyan
      default:
        return const Color(0xFF7C4DFF); // Purpura
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(analyticsDamaRankingProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);

    return rankingAsync.when(
      loading: () => ListView.builder(
        padding: MediaQuery.of(context).size.width >= 900
            ? const EdgeInsets.fromLTRB(0, 8, 0, 12)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ShimmerPlaceholder(
            width: double.infinity,
            height: 90,
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error al cargar comisiones: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (damas) {
        if (damas.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline_rounded, size: 64.0, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 16.0),
                Text(
                  'No hay comisiones registradas',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final double maxCommissions = damas.first.comisionesAcumuladas;

        return ListView.builder(
          padding: MediaQuery.of(context).size.width >= 900
              ? const EdgeInsets.fromLTRB(0, 8, 0, 12)
              : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          physics: const BouncingScrollPhysics(),
          itemCount: damas.length,
          itemBuilder: (context, index) {
            final d = damas[index];
            final rank = index + 1;
            final rankColor = _getRankColor(rank);
            final double sharePercent = maxCommissions == 0 ? 0.0 : (d.comisionesAcumuladas / maxCommissions);

            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2024),
                borderRadius: BorderRadius.circular(16.0),
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
                            style: GoogleFonts.poppins(
                              color: rankColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),

                      // Avatar Circular
                      CircleAvatar(
                        radius: 20.0,
                        backgroundColor: rankColor.withOpacity(0.15),
                        child: Text(
                          d.nombre.isNotEmpty ? d.nombre[0].toUpperCase() : 'D',
                          style: GoogleFonts.poppins(
                            color: rankColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14.0),

                      // Nombre de la Dama
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.nombre,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '${d.turnosCompania} turnos • ${d.invitacionesReceivedLabel}',
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

                      // Comisiones Acumuladas
                      Text(
                        CurrencyHelper.formatWithSymbol(d.comisionesAcumuladas, currencySymbol, currencyIso),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00F0FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),

                  // Barra de Proporción Relativa a la Dama #1
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

extension on DamaRankingModel {
  String get invitacionesReceivedLabel {
    if (invitacionesRecibidas == 1) {
      return '1 invitación';
    }
    return '$invitacionesRecibidas invitaciones';
  }
}
