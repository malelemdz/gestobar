import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_helper.dart';

class CierreSummaryDialog extends StatelessWidget {
  final dynamic resumen;
  final String currencySymbol;
  final String currencyIso;

  const CierreSummaryDialog({
    super.key,
    required this.resumen,
    required this.currencySymbol,
    required this.currencyIso,
  });

  @override
  Widget build(BuildContext context) {
    final mInicial = (resumen['monto_inicial'] as num?)?.toDouble() ?? 0.0;
    final vTotales = (resumen['ventas_totales'] as num?)?.toDouble() ?? 0.0;
    final comisiones = (resumen['comisiones_pagadas'] as num?)?.toDouble() ?? 0.0;
    final ingresos = (resumen['ingresos_manuales'] as num?)?.toDouble() ?? 0.0;
    final egresos = (resumen['egresos_manuales'] as num?)?.toDouble() ?? 0.0;
    final esperado = (resumen['balance_esperado'] as num?)?.toDouble() ?? 0.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2024),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long, color: Color(0xFF00F0FF), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TURNO CERRADO',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Resumen Financiero del Sistema',
                          style: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Desglose de saldos final
              _buildSummaryRow('Dinero Inicial (Fondo):', '$currencySymbol ${CurrencyHelper.formatAmount(mInicial, currencyIso)}', Colors.white54),
              _buildSummaryRow('(+) Ventas Totales POS:', '$currencySymbol ${CurrencyHelper.formatAmount(vTotales, currencyIso)}', const Color(0xFF00F0FF)),
              _buildSummaryRow('(+) Ingresos Manuales:', '$currencySymbol ${CurrencyHelper.formatAmount(ingresos, currencyIso)}', const Color(0xFF00FF66)),
              _buildSummaryRow('(-) Egresos Manuales:', '$currencySymbol ${CurrencyHelper.formatAmount(egresos, currencyIso)}', Colors.redAccent),
              _buildSummaryRow('(-) Comisiones Damas:', '$currencySymbol ${CurrencyHelper.formatAmount(comisiones, currencyIso)}', const Color(0xFFFF00D6)),
              const SizedBox(height: 10),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              _buildSummaryRow('Dinero Total Entregado:', '$currencySymbol ${CurrencyHelper.formatAmount(esperado, currencyIso)}', Colors.white, isTotal: true),

              const SizedBox(height: 28),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7000FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('ENTENDIDO', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valColor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: isTotal ? Colors.white : Colors.white30,
              fontSize: isTotal ? 13 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: valColor,
              fontWeight: FontWeight.w900,
              fontSize: isTotal ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
