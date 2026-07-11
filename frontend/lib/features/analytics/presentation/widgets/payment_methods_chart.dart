import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/utils/currency_helper.dart';
import '../../../caja/providers/caja_provider.dart';
import '../../data/models/analytics_resumen_model.dart';

class PaymentMethodsChart extends ConsumerWidget {
  final List<PaymentMethodBreakdown> breakdown;

  const PaymentMethodsChart({super.key, required this.breakdown});

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'EFECTIVO':
        return const Color(0xFF00F0FF); // Cyan
      case 'TARJETA':
        return const Color(0xFFE040FB); // Violet
      case 'TRANSFERENCIA':
      case 'TRANSFERENCIA/QR':
      case 'TRANSFERENCIA_QR':
      case 'QR':
        return const Color(0xFFFFB1C3); // Pink / Rose
      default:
        return const Color(0xFFDBFCFF); // Light blue
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method.toUpperCase()) {
      case 'EFECTIVO':
        return Icons.money_rounded;
      case 'TARJETA':
        return Icons.credit_card_rounded;
      case 'TRANSFERENCIA':
      case 'TRANSFERENCIA/QR':
      case 'TRANSFERENCIA_QR':
      case 'QR':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    if (breakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            'Sin desglose de pagos disponible',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }

    final double totalVolume = breakdown.map((e) => e.total).reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Distribución por Método de Pago',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12.0),
          ...breakdown.map((item) {
            final double percent = totalVolume == 0 ? 0.0 : (item.total / totalVolume);
            final color = _getMethodColor(item.metodo);
            final icon = _getMethodIcon(item.metodo);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(icon, color: color, size: 20.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.metodo.toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${CurrencyHelper.formatWithSymbol(item.total, currencySymbol, currencyIso)} (${(percent * 100).toStringAsFixed(1)}%)',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Container(
                            height: 6.0,
                            color: Colors.white.withOpacity(0.03),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percent.clamp(0.0, 1.0),
                              child: Container(
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
