import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/features/auth/models/user_model.dart';

class DashboardSessionCard extends StatelessWidget {
  final UserModel user;
  final String? activeBarId;
  final String barName;

  const DashboardSessionCard({
    super.key,
    required this.user,
    required this.activeBarId,
    required this.barName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(32.0),
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
              children: [
                // Avatar circular con iniciales
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
                  child: Center(
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
                const SizedBox(width: 16.0),
                // Datos de sesión (Nombre, Rol)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${user.nombre}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        user.username,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),
            // Línea divisoria minimalista
            Divider(color: Colors.white.withOpacity(0.06), height: 1.0),
            const SizedBox(height: 20.0),
            // Fila de Metadatos (Rol y Sucursal)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROL OPERATIVO',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0x1A7000FF),
                        borderRadius: BorderRadius.circular(100.0),
                        border: Border.all(color: const Color(0x337000FF)),
                      ),
                      child: Text(
                        user.rolNombre.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFD1BCFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 9.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SUCURSAL ACTIVA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      activeBarId != null ? barName : 'CONSOLA GLOBAL',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.0,
                        color: const Color(0xFF00F0FF),
                      ),
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
