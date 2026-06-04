import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';

class ConfigWarningSheet extends StatefulWidget {
  final bool changedCurrency;
  final bool changedTimezone;

  const ConfigWarningSheet({
    super.key,
    required this.changedCurrency,
    required this.changedTimezone,
  });

  @override
  State<ConfigWarningSheet> createState() => _ConfigWarningSheetState();
}

class _ConfigWarningSheetState extends State<ConfigWarningSheet> {
  late TextEditingController _confirmCtrl;

  @override
  void initState() {
    super.initState();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E2024),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.colorWarning, size: 48),
            const SizedBox(height: 16),
            Text(
              'CAMBIOS CRÍTICOS DETECTADOS',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.changedCurrency)
              Text(
                'Has cambiado la Moneda. El sistema migrará matemáticamente TODOS los precios de tu Menú para ajustarlos a la escala correcta (Ej: 27.42 a 27.420).',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
            if (widget.changedCurrency && widget.changedTimezone) const SizedBox(height: 12),
            if (widget.changedTimezone)
              Text(
                'Has cambiado la Zona Horaria. Los reportes de ventas históricos podrían desfasarse en tiempo.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
            const SizedBox(height: 24),
            Text(
              'Escribe "CONFIRMAR" para proceder:',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'CONFIRMAR',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_confirmCtrl.text.trim().toUpperCase() == 'CONFIRMAR') {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colorWarning,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Entendido, Cambiar',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
