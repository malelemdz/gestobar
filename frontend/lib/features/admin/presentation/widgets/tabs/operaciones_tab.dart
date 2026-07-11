import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/core/utils/currency_helper.dart';
import '../config_bento_card.dart';
import '../config_dropdown_field.dart';

class OperacionesTab extends StatelessWidget {
  final String currentIso;
  final String currentTimezone;
  final bool isCajaAbierta;
  final void Function(String) onIsoChanged;
  final void Function(String) onTimezoneChanged;

  static const List<String> isoOptions = [
    'USD', 'BOB', 'BRL', 'CLP', 'COP', 'CRC', 'CUP', 'DOP', 'EUR', 'GTQ',
    'HNL', 'MXN', 'NIO', 'PAB', 'PEN', 'PYG', 'SVC', 'UYU', 'VES'
  ];

  static const List<String> timezoneOptions = [
    'America/New_York', 'America/Chicago', 'America/Denver', 'America/Los_Angeles',
    'Europe/Madrid', 'Atlantic/Canary', 'America/La_Paz', 'America/Lima',
    'America/Santiago', 'America/Bogota', 'America/Mexico_City', 'America/Monterrey',
    'America/Tijuana', 'America/Argentina/Buenos_Aires', 'America/Sao_Paulo',
    'America/Manaus', 'America/Costa_Rica', 'America/El_Salvador', 'America/Guatemala',
    'America/Tegucigalpa', 'America/Managua', 'America/Panama', 'America/Asuncion',
    'America/Caracas', 'America/Montevideo', 'America/Guayaquil', 'America/Santo_Domingo',
    'America/Puerto_Rico', 'America/Havana'
  ];

  const OperacionesTab({
    super.key,
    required this.currentIso,
    required this.currentTimezone,
    required this.isCajaAbierta,
    required this.onIsoChanged,
    required this.onTimezoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              ConfigBentoCard(
                title: 'Operaciones',
                description: 'Configura la moneda de transacciones y la zona horaria local.',
                icon: Icons.monetization_on_outlined,
                child: Column(
                  children: [
                    if (isCajaAbierta)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.colorDanger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.colorDanger.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_clock, color: AppTheme.colorDanger, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Existe una caja abierta actualmente. Para evitar descuadres en el arqueo, debes cerrarla antes de modificar la Moneda o Zona Horaria.',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.colorDanger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 400;
                        if (isMobile) {
                          return Column(
                            children: [
                              ConfigDropdownField<String>(
                                label: 'Moneda del Bar',
                                value: currentIso,
                                items: isoOptions
                                    .map((iso) => DropdownMenuItem(
                                          value: iso,
                                          child: Text(CurrencyHelper.getCurrencyLabel(iso)),
                                        ))
                                    .toList(),
                                onChanged: isCajaAbierta
                                    ? null
                                    : (val) {
                                        if (val != null) onIsoChanged(val);
                                      },
                              ),
                              const SizedBox(height: 12),
                              ConfigDropdownField<String>(
                                label: 'Zona Horaria',
                                value: currentTimezone,
                                items: timezoneOptions
                                    .map((tz) => DropdownMenuItem(
                                          value: tz,
                                          child: Text(
                                            tz,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: isCajaAbierta
                                    ? null
                                    : (val) {
                                        if (val != null) onTimezoneChanged(val);
                                      },
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: ConfigDropdownField<String>(
                                  label: 'Moneda del Bar',
                                  value: currentIso,
                                  items: isoOptions
                                      .map((iso) => DropdownMenuItem(
                                            value: iso,
                                            child: Text(CurrencyHelper.getCurrencyLabel(iso)),
                                          ))
                                      .toList(),
                                  onChanged: isCajaAbierta
                                      ? null
                                      : (val) {
                                          if (val != null) onIsoChanged(val);
                                        },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ConfigDropdownField<String>(
                                  label: 'Zona Horaria',
                                  value: currentTimezone,
                                  items: timezoneOptions
                                      .map((tz) => DropdownMenuItem(
                                            value: tz,
                                            child: Text(
                                              tz,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: isCajaAbierta
                                      ? null
                                      : (val) {
                                          if (val != null) onTimezoneChanged(val);
                                        },
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildCurrencyPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyPreview() {
    final symbol = CurrencyHelper.getSymbolFromIso(currentIso);
    final decimals = CurrencyHelper.getDecimalDigits(currentIso);
    final double sampleAmount = decimals == 0 ? 7500.0 : 75.00;
    final formatted = CurrencyHelper.formatAmount(sampleAmount, currentIso);
    final String sourceText = decimals == 0 ? '75,00' : '7.500';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00F0FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.visibility_outlined, color: Color(0xFF00F0FF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VISTA PREVIA DEL FORMATO',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(text: 'Los cobros de $sourceText se verán como: '),
                      TextSpan(
                        text: '$symbol $formatted',
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'La moneda $currentIso usa $decimals decimales.',
                  style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
