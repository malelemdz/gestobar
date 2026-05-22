import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import 'main_dashboard_view.dart'; // Para activeViewProvider
import '../../admin/providers/bar_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final barState = ref.watch(currentBarProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tarjeta Premium de Sesión Activa (Liquid Modernist Style)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024), // surface-container
              borderRadius: BorderRadius.circular(32.0), // Extreme rounded modernist corners!
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
                              color: const Color(0x1A7000FF), // violet with 10% opacity
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
                            authState.activeBarId != null
                                ? barState.when(
                                    data: (bar) => bar.nombre,
                                    loading: () => 'Cargando...',
                                    error: (_, __) => 'Error al cargar',
                                  )
                                : 'CONSOLA GLOBAL',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16.0,
                              color: const Color(0xFF00F0FF), // electric cyan
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // 2. Grilla Bento de Accesos Rápidos
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width >= 750 ? 4 : 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: MediaQuery.of(context).size.width >= 750 ? 1.4 : 1.3,
            children: [
              _buildBentoItem(
                context: context,
                icon: Icons.point_of_sale,
                title: 'POS Ventas',
                subtitle: 'Ir a facturación',
                color: const Color(0xFF00F0FF), // electric cyan
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'pos';
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.payments,
                title: 'Caja',
                subtitle: 'Control de turnos',
                color: const Color(0xFFFFB1C3), // warm rose
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'caja';
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.local_bar,
                title: 'Menú',
                subtitle: 'Editar catálogo',
                color: const Color(0xFF7000FF), // vibrant violet
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'menu';
                },
              ),
              _buildBentoItem(
                context: context,
                icon: Icons.people_alt,
                title: 'Staff',
                subtitle: 'Personal y roles',
                color: const Color(0xFFDBFCFF), // mint/cyan fixed dim
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'staff';
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024), // surface-container
        borderRadius: BorderRadius.circular(32.0), // 32px rounded corners!
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(icon, color: color, size: 20.0),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 16.0,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 11.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
