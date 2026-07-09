import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import '../../../admin/providers/bar_provider.dart';
import '../../providers/caja_provider.dart';

class ClosedCajasHistoryList extends ConsumerWidget {
  final void Function(String cajaId) onCajaTap;

  const ClosedCajasHistoryList({
    super.key,
    required this.onCajaTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(cajaHistoryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final barTimezone = ref.watch(barTimezoneProvider);

    return historyState.when(
      data: (list) {
        // Filtrar solo las cajas cerradas para mostrar en el historial
        final closedList = list.where((c) => c.estado == 'CERRADA').toList();

        if (closedList.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                'No hay turnos de caja cerrados registrados.',
                style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 13),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: closedList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12.0),
          itemBuilder: (context, index) {
            final c = closedList[index];
            final fApertura = DateFormat('dd/MM/yyyy • HH:mm').format(
              TimezoneHelper.convertToBarTime(c.fechaApertura, barTimezone),
            );
            final fCierre = c.fechaCierre != null
                ? DateFormat('dd/MM/yyyy • HH:mm').format(
                    TimezoneHelper.convertToBarTime(c.fechaCierre!, barTimezone),
                  )
                : 'En curso';

            final barmanApertura = c.aperturaUsuario?.nombre ?? 'Cajero';
            final barmanCierre = c.cierreUsuario?.nombre ?? 'Cajero';

            final formattedInicial = CurrencyHelper.formatAmount(c.montoInicial, currencyIso);
            final formattedFinal = c.montoFinal != null
                ? CurrencyHelper.formatAmount(c.montoFinal!, currencyIso)
                : '0.00';

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onCajaTap(c.id),
                borderRadius: BorderRadius.circular(16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2024),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.04),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado con estado y montos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(color: Colors.white24, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_outline, color: Colors.white30, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  'CERRADA',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white30,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$currencySymbol $formattedFinal',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00FF66),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),

                      // Detalles de fechas
                      _buildInfoRow(Icons.vpn_key_outlined, 'Apertura:', '$fApertura por $barmanApertura'),
                      const SizedBox(height: 6.0),
                      _buildInfoRow(Icons.lock_clock_outlined, 'Cierre:', '$fCierre por $barmanCierre'),
                      
                      const SizedBox(height: 12.0),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 12.0),

                      // Resumen rápido
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fondo Inicial:',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 11),
                          ),
                          Text(
                            '$currencySymbol $formattedInicial',
                            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(height: 12.0),
        itemBuilder: (context, index) => const ShimmerPlaceholder(
          width: double.infinity,
          height: 150,
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Text(
            'Error al cargar historial: $err',
            style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white30, size: 13),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
