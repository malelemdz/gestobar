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

class MovementDetailBottomSheet extends ConsumerWidget {
  final EventoMovimiento ev;
  final String currencySymbol;
  final String currencyIso;
  final bool isDialog;

  const MovementDetailBottomSheet({
    super.key,
    required this.ev,
    required this.currencySymbol,
    required this.currencyIso,
    this.isDialog = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVenta = ev.tipo == 'VENTA';
    final barTimezone = ref.watch(barTimezoneProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: isDialog
            ? BorderRadius.circular(24.0)
            : const BorderRadius.vertical(top: Radius.circular(16.0)),
        border: isDialog
            ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDialog) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12.0),
          ],
          Text(
            isVenta ? 'TICKET DE COMPRA' : 'DETALLE DE CAJA CHICA',
            style: GoogleFonts.poppins(
              color: isVenta
                  ? const Color(0xFF00F0FF)
                  : (ev.tipo == 'INGRESO' ? const Color(0xFF00FF66) : Colors.redAccent),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),

          // Contenido Dinámico
          isVenta
              ? _buildTicketDetails(ev.original as VentaModel, currencySymbol, currencyIso, barTimezone)
              : _buildManualMovementDetails(ev.original as CajaMovimientoModel, currencySymbol, currencyIso, barTimezone),

          const SizedBox(height: 12.0),

          Center(
            child: SizedBox(
              width: isDialog ? 250.0 : double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.04),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Text(
                  'CERRAR TICKET',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetails(VentaModel venta, String symbol, String iso, String barTimezone) {
    final String barmanNombre = venta.usuario != null ? venta.usuario!.nombre : 'Cajero';
    final String fecha = DateFormat('dd/MM/yyyy • HH:mm').format(
      TimezoneHelper.convertToBarTime(venta.fecha, barTimezone),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            children: [
              _buildTicketDetailRow('Ticket ID:', venta.id.substring(0, 8).toUpperCase(), Colors.white70),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Cajero:', barmanNombre, Colors.white),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Fecha y Hora:', fecha, Colors.white54),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Canal de Pago:', venta.metodoPago, const Color(0xFF00F0FF)),
            ],
          ),
        ),
        const SizedBox(height: 12.0),

        Text(
          'ARTÍCULOS CONSUMIDOS',
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),

        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: venta.detalles.length,
          separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
          itemBuilder: (context, index) {
            final d = venta.detalles[index];
            final String variantName = d.variante?.nombre ?? 'Genérico';
            final String productName = d.productoNombre;
            final String name = '$productName ($variantName)';

            final double subtotal = d.precioUnitario * d.cantidad;
            final formattedSubtotal = CurrencyHelper.formatAmount(subtotal, iso);
            final formattedPrice = CurrencyHelper.formatAmount(d.precioUnitario, iso);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${d.cantidad}x $symbol $formattedPrice',
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$symbol $formattedSubtotal',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (d.dama != null || d.esInvitacion) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          d.esInvitacion ? Icons.card_giftcard : Icons.female,
                          size: 11,
                          color: d.esInvitacion ? const Color(0xFF00FF66) : const Color(0xFFFF00D6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          d.esInvitacion
                              ? 'Invitación Especial (Sin comisión)'
                              : 'Asignado a: ${d.dama!.nombre} (Comisión: $symbol ${CurrencyHelper.formatAmount(d.comisionDama * d.cantidad, iso)})',
                          style: GoogleFonts.poppins(
                            color: d.esInvitacion ? const Color(0xFF00FF66) : const Color(0xFFFF00D6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12.0),
        const Divider(color: Colors.white10),
        const SizedBox(height: 10),

        if (venta.metodoPago == 'MIXTO') ...[
          _buildTicketDetailRow('Pago Efectivo:', '$symbol ${CurrencyHelper.formatAmount(venta.montoEfectivo, iso)}', Colors.white54),
          const SizedBox(height: 4),
          _buildTicketDetailRow('Pago Tarjeta:', '$symbol ${CurrencyHelper.formatAmount(venta.montoTarjeta, iso)}', Colors.white54),
          const SizedBox(height: 4),
          _buildTicketDetailRow('Pago Transf/QR:', '$symbol ${CurrencyHelper.formatAmount(venta.montoTrQr, iso)}', Colors.white54),
          const SizedBox(height: 8),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF7000FF).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFF7000FF).withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL COBRADO:',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00F0FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                '$symbol ${CurrencyHelper.formatAmount(venta.total, iso)}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00F0FF),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualMovementDetails(CajaMovimientoModel m, String symbol, String iso, String barTimezone) {
    final String barmanNombre = m.usuario != null ? m.usuario!.nombre : 'Cajero';
    final String fecha = DateFormat('dd/MM/yyyy • HH:mm').format(
      TimezoneHelper.convertToBarTime(m.createdAt, barTimezone),
    );
    final bool isIngreso = m.tipo == 'INGRESO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isIngreso ? const Color(0xFF00FF66).withOpacity(0.08) : Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: isIngreso ? const Color(0xFF00FF66).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  isIngreso ? 'INGRESO DE CAJA CHICA' : 'EGRESO DE CAJA CHICA',
                  style: GoogleFonts.poppins(
                    color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            children: [
              _buildTicketDetailRow('Cajero:', barmanNombre, Colors.white),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Fecha y Hora:', fecha, Colors.white54),
              const SizedBox(height: 6),
              _buildTicketDetailRow('Método Utilizado:', m.metodoPago, Colors.white70),
            ],
          ),
        ),
        const SizedBox(height: 12.0),

        Text(
          'CONCEPTO / DESCRIPCIÓN',
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Text(
            m.concepto.isNotEmpty ? m.concepto : 'Sin descripción registrada.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12.0),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isIngreso ? const Color(0xFF00FF66).withOpacity(0.05) : Colors.redAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: isIngreso ? const Color(0xFF00FF66).withOpacity(0.1) : Colors.redAccent.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MONTO OPERACIÓN:',
                style: GoogleFonts.poppins(
                  color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              Text(
                '${isIngreso ? '+' : '-'} $symbol ${CurrencyHelper.formatAmount(m.monto, iso)}',
                style: GoogleFonts.poppins(
                  color: isIngreso ? const Color(0xFF00FF66) : Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white30,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
