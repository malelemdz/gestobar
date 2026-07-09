import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/currency_helper.dart';

class ClosedCajaPanel extends StatelessWidget {
  final TextEditingController montoController;
  final bool isLoading;
  final String currencySymbol;
  final String currencyIso;
  final VoidCallback onAbrirCaja;

  const ClosedCajaPanel({
    super.key,
    required this.montoController,
    required this.isLoading,
    required this.currencySymbol,
    required this.currencyIso,
    required this.onAbrirCaja,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024), // surface-container
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAJA CERRADA',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Debe abrir un turno para iniciar ventas y comisiones.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Entrada de dinero inicial obligatoria
          Text(
            'Efectivo inicial en gaveta.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF282A30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: montoController,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                CurrencyInputFormatter(iso: currencyIso),
              ],
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Ingresa 0 si abres con gaveta vacía',
                hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 13),
                prefixIcon: Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    currencySymbol,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF00F0FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  maxWidth: 48,
                  minHeight: 48,
                  maxHeight: 48,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(right: 16),
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Botón Confirmar Apertura
          InkWell(
            onTap: isLoading ? null : onAbrirCaja,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.liquidPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.liquidPrimary.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Abrir caja',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF14161A),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
