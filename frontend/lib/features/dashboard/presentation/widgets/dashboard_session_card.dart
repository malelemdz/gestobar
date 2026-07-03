import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gestobar/core/utils/timezone_helper.dart';
import 'package:gestobar/features/auth/models/user_model.dart';
import 'package:gestobar/features/admin/providers/bar_provider.dart';
import 'package:gestobar/core/constants/api_constants.dart';

class DashboardSessionCard extends ConsumerWidget {
  final UserModel user;
  final String? activeBarId;
  final String barName;

  const DashboardSessionCard({
    super.key,
    required this.user,
    required this.activeBarId,
    required this.barName,
  });

  Widget _buildFallbackBarLogo(ThemeData theme, {double size = 42.0}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0x1A00F0FF),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0x3300F0FF)),
      ),
      child: Center(
        child: Icon(Icons.local_bar, size: size * 0.5, color: const Color(0xFF00F0FF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final barTimezone = ref.watch(barTimezoneProvider);
    final barState = ref.watch(currentBarProvider);

    final String? logoUrl = barState.maybeWhen(
      data: (bar) => bar.logoUrl,
      orElse: () => null,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Avatar circular con foto o iniciales
                 Container(
                   width: 56.0,
                   height: 56.0,
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(
                       colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                     ),
                     borderRadius: BorderRadius.circular(100.0),
                     boxShadow: [
                       BoxShadow(
                         color: const Color(0xFF7000FF).withOpacity(0.3),
                         blurRadius: 12.0,
                         offset: const Offset(0, 4),
                       ),
                     ],
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(100.0),
                     child: (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                         ? Image.network(
                             ApiConstants.resolveImageUrl(user.fotoUrl)!,
                             fit: BoxFit.cover,
                             errorBuilder: (context, error, stackTrace) {
                               return Center(
                                 child: Text(
                                   (user.nombre.isNotEmpty ? user.nombre.substring(0, 1) : 'U').toUpperCase(),
                                   style: GoogleFonts.plusJakartaSans(
                                     color: Colors.white,
                                     fontSize: 20.0,
                                     fontWeight: FontWeight.w900,
                                   ),
                                 ),
                               );
                             },
                           )
                         : Center(
                             child: Text(
                               (user.nombre.isNotEmpty ? user.nombre.substring(0, 1) : 'U').toUpperCase(),
                               style: GoogleFonts.plusJakartaSans(
                                 color: Colors.white,
                                 fontSize: 20.0,
                                 fontWeight: FontWeight.w900,
                               ),
                             ),
                           ),
                   ),
                 ),
                const SizedBox(width: 16.0),
                // Datos de sesión (Nombre, Rol • @username)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Hola, ${user.nombre.split(' ').first}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${user.rolNombre.toUpperCase()} • @${user.username}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Reloj en tiempo real
                LocalTimeClock(timezone: barTimezone),
              ],
            ),
            const SizedBox(height: 24.0),
            // Línea divisoria minimalista
            Divider(color: Colors.white.withOpacity(0.06), height: 1.0),
            const SizedBox(height: 20.0),
            // Fila de Metadatos (Nombre del Bar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NOMBRE DEL BAR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (logoUrl != null && logoUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              logoUrl,
                              width: 42.0,
                              height: 42.0,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackBarLogo(theme, size: 42.0),
                            ),
                          )
                        else
                          _buildFallbackBarLogo(theme, size: 42.0),
                        const SizedBox(width: 10.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeBarId != null ? barName : 'CONSOLA GLOBAL',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 18.0,
                                color: const Color(0xFF00F0FF),
                              ),
                            ),
                            if (activeBarId != null)
                              barState.maybeWhen(
                                data: (bar) {
                                  final list = <String>[];
                                  if (bar.direccion != null && bar.direccion!.trim().isNotEmpty) {
                                    list.add(bar.direccion!.trim());
                                  }
                                  if (bar.ciudad != null && bar.ciudad!.trim().isNotEmpty) {
                                    list.add(bar.ciudad!.trim());
                                  }
                                  if (list.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      list.join(', '),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  );
                                },
                                orElse: () => const SizedBox.shrink(),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LocalTimeClock extends ConsumerStatefulWidget {
  final String timezone;
  const LocalTimeClock({super.key, required this.timezone});

  @override
  ConsumerState<LocalTimeClock> createState() => _LocalTimeClockState();
}

class _LocalTimeClockState extends ConsumerState<LocalTimeClock> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String _getFormattedDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final days = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    final dayStr = days[date.weekday - 1];
    final monthStr = months[date.month - 1];
    return '$dayStr, ${date.day} de $monthStr';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offsetState = ref.watch(serverTimeOffsetProvider);

    return offsetState.when(
      data: (offset) {
        final syncedTime = DateTime.now().add(offset);
        final barTime = TimezoneHelper.convertToBarTime(syncedTime, widget.timezone);
        final timeStr = DateFormat('HH:mm:ss').format(barTime);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getFormattedDate(barTime).toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              timeStr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF00F0FF),
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      },
      loading: () {
        return const SizedBox(
          height: 32,
          width: 80,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
              ),
            ),
          ),
        );
      },
      error: (_, __) {
        final syncedTime = DateTime.now();
        final barTime = TimezoneHelper.convertToBarTime(syncedTime, widget.timezone);
        final timeStr = DateFormat('HH:mm:ss').format(barTime);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getFormattedDate(barTime).toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              timeStr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF00F0FF),
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}
