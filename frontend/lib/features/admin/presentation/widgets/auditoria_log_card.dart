import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../data/models/auditoria_model.dart';
import '../utils/auditoria_formatters.dart';

class AuditoriaLogCard extends StatelessWidget {
  final AuditoriaModel log;
  final String currencyIso;
  final String currencySymbol;
  final String barTimezone;

  const AuditoriaLogCard({
    super.key,
    required this.log,
    required this.currencyIso,
    required this.currencySymbol,
    required this.barTimezone,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd MMM, HH:mm:ss');
    final localFecha = TimezoneHelper.convertToBarTime(log.fecha, barTimezone);
    final dateStr = format.format(localFecha);

    Color actionColor = AppTheme.liquidPrimary;
    IconData actionIcon = Icons.info_outline;

    if (log.accion == 'Crear') {
      actionColor = AppTheme.colorSuccess;
      actionIcon = Icons.add_circle_outline;
    } else if (log.accion == 'Editar') {
      actionColor = Colors.orangeAccent;
      actionIcon = Icons.edit_outlined;
    } else if (log.accion == 'Eliminar') {
      actionColor = AppTheme.colorWarning;
      actionIcon = Icons.delete_outline;
    } else if (log.accion == 'Inicio de Sesión') {
      actionColor = Colors.cyanAccent;
      actionIcon = Icons.vpn_key_outlined;
    } else if (log.accion == 'Inicio de Sesión Fallido') {
      actionColor = AppTheme.colorDanger;
      actionIcon = Icons.gpp_bad_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.liquidSurfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(actionIcon, color: actionColor, size: 20),
              const SizedBox(width: 8),
              Text(
                AuditoriaFormatters.formatAction(log.accion),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: actionColor,
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AuditoriaFormatters.formatMessageWithCurrency(
              log.detalles?['mensaje'],
              currencyIso,
              currencySymbol,
            ),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.5, color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${log.usuarioNombre ?? "Usuario"} (${log.rolNombre.toLowerCase()})',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.folder_open, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                AuditoriaFormatters.formatModulo(log.modulo),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          if (log.dispositivo != null || log.ipAddress != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (log.dispositivo != null) ...[
                  const Icon(Icons.devices, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      log.dispositivo!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white38),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (log.ipAddress != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.network_wifi, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    AuditoriaFormatters.formatIpAddress(log.ipAddress),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ],
            ),
          ]
        ],
      ),
    );
  }
}
