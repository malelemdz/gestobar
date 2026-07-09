import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../../admin/providers/bar_provider.dart';
import '../../models/caja_model.dart';
import '../../models/evento_movimiento.dart';
import '../../models/venta_model.dart';

class MovimientosList extends ConsumerWidget {
  final List<CajaMovimientoModel> movimientos;
  final List<VentaModel> ventas;
  final String currencySymbol;
  final String currencyIso;
  final void Function(EventoMovimiento ev) onMovementDetail;

  const MovimientosList({
    super.key,
    required this.movimientos,
    required this.ventas,
    required this.currencySymbol,
    required this.currencyIso,
    required this.onMovementDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barTimezone = ref.watch(barTimezoneProvider);
    // 1. Unificar y ordenar cronológicamente DESC
    final List<EventoMovimiento> eventos = [];

    for (final m in movimientos) {
      eventos.add(EventoMovimiento(
        id: m.id,
        tipo: m.tipo, // 'INGRESO' o 'EGRESO'
        fecha: m.createdAt,
        monto: m.monto,
        metodoPago: m.metodoPago,
        concepto: m.concepto,
        cajero: m.usuario?.nombre ?? 'Cajero',
        original: m,
      ));
    }

    for (final v in ventas) {
      final String conceptoVenta = v.detalles.isNotEmpty
          ? v.detalles.map((d) => '${d.cantidad}x ${d.productoNombre}').join(', ')
          : 'Venta POS';

      eventos.add(EventoMovimiento(
        id: v.id,
        tipo: 'VENTA',
        fecha: v.fecha,
        monto: v.total,
        metodoPago: v.metodoPago,
        concepto: conceptoVenta,
        cajero: v.usuario?.nombre ?? 'Cajero',
        original: v,
      ));
    }

    // Ordenar de más reciente a más antiguo
    eventos.sort((a, b) => b.fecha.compareTo(a.fecha));

    if (eventos.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Center(
          child: Text(
            'Sin eventos ni movimientos registrados en este turno.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 11),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'BITÁCORA UNIFICADA DE EVENTOS (TIEMPO REAL)',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12.0),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: eventos.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final ev = eventos[index];
              final String tipo = ev.tipo;
              final bool isIngreso = tipo == 'INGRESO';
              final bool isEgreso = tipo == 'EGRESO';
              final bool isVenta = tipo == 'VENTA';

              final barTime = TimezoneHelper.convertToBarTime(ev.fecha, barTimezone);
              final time = DateFormat('HH:mm').format(barTime);
              final formattedMonto = CurrencyHelper.formatAmount(ev.monto, currencyIso);

              Color iconBgColor = Colors.white.withOpacity(0.05);
              Color iconColor = Colors.white;
              IconData icon = Icons.info_outline;

              if (isIngreso) {
                iconBgColor = const Color(0xFF00FF66).withOpacity(0.1);
                iconColor = const Color(0xFF00FF66);
                icon = Icons.arrow_upward;
              } else if (isEgreso) {
                iconBgColor = Colors.redAccent.withOpacity(0.1);
                iconColor = Colors.redAccent;
                icon = Icons.arrow_downward;
              } else if (isVenta) {
                iconBgColor = const Color(0xFF7000FF).withOpacity(0.1);
                iconColor = const Color(0xFF00F0FF);
                icon = Icons.receipt_long_outlined;
              }

              return InkWell(
                onTap: () => onMovementDetail(ev),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVenta ? 'VENTA POS • TICKET' : ev.concepto,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isVenta)
                              Text(
                                ev.concepto,
                                style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              'Vía ${ev.metodoPago} • $time por ${ev.cajero}',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(isIngreso || isVenta) ? '+' : '-'} $currencySymbol $formattedMonto',
                        style: GoogleFonts.plusJakartaSans(
                          color: isIngreso ? const Color(0xFF00FF66) : (isVenta ? const Color(0xFF00F0FF) : Colors.redAccent),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
