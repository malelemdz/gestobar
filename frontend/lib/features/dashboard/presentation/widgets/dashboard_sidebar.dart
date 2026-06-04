import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/features/auth/models/user_model.dart';

class DashboardSidebar extends StatelessWidget {
  final String barName;
  final String? activeBarId;
  final String role;
  final UserModel user;
  final List<Map<String, dynamic>> navItems;
  final String activeView;
  final void Function(String) onViewChanged;
  final VoidCallback onLogout;
  final VoidCallback onAboutTap;

  const DashboardSidebar({
    super.key,
    required this.barName,
    required this.activeBarId,
    required this.role,
    required this.user,
    required this.navItems,
    required this.activeView,
    required this.onViewChanged,
    required this.onLogout,
    required this.onAboutTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String displayBarName = activeBarId != null ? barName : 'Gestobar';
    final String barSubtitle = activeBarId != null ? 'Bar Management' : 'Global Console';

    return Container(
      width: 260.0,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C20),
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del Sidebar: Logo y título Neon Lounge
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayBarName,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primaryContainer,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  barSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.0,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Lista de Módulos Operativos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final String viewId = item['view'] as String;
                final bool isSelected = activeView == viewId;

                return _buildSidebarNavItem(
                  context: context,
                  icon: isSelected ? item['icon_active'] as IconData : item['icon'] as IconData,
                  label: item['label'] as String,
                  isSelected: isSelected,
                  onTap: () => onViewChanged(viewId),
                );
              },
            ),
          ),

          // MENÚ DE OPCIONES DE CONFIGURACIÓN Y SOPORTE (SIDEBAR BOTTOM)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botón de Acción Principal: Nueva Venta / Nueva Orden
                if (role == 'ADMIN' || role == 'SUPERADMIN' || role == 'BARMAN') ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      height: 48.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100.0),
                        color: theme.colorScheme.primaryContainer,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100.0),
                          onTap: () => onViewChanged('pos'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add,
                                size: 20.0,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'NUEVA ORDEN',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.0,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const Divider(color: Color(0xFF282A2E), height: 1.0),
                const SizedBox(height: 12.0),

                // Opción: Soporte & Perfil
                _buildSidebarBottomItem(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Mi Perfil',
                  isSelected: activeView == 'perfil',
                  onTap: () => onViewChanged('perfil'),
                ),
                const SizedBox(height: 4.0),

                if (role == 'SUPERADMIN' || role == 'ADMIN') ...[
                  _buildSidebarBottomItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    label: 'Configuración',
                    isSelected: activeView == 'config',
                    onTap: () => onViewChanged('config'),
                  ),
                  const SizedBox(height: 4.0),
                ],

                _buildSidebarBottomItem(
                  context: context,
                  icon: Icons.info_outline,
                  label: 'Acerca de',
                  isSelected: false,
                  onTap: onAboutTap,
                ),
                const SizedBox(height: 8.0),

                // Perfil de Usuario Premium Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18.0,
                        backgroundColor: theme.colorScheme.secondary.withOpacity(0.15),
                        child: Text(
                          user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nombre,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.0,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              role,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 8.0,
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, size: 16.0, color: AppTheme.colorDanger),
                        onPressed: onLogout,
                        tooltip: 'Cerrar Sesión',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x2600F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(100.0),
          border: Border.all(
            color: isSelected ? const Color(0x3300F0FF) : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(100.0),
            onTap: onTap,
            child: Container(
              height: 48.0,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20.0,
                    color: isSelected ? const Color(0xFF00F0FF) : Colors.white.withOpacity(0.4),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF00F0FF) : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarBottomItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color activeColor = const Color(0xFF00F0FF);
    final Color activeBg = const Color(0x2600F0FF);
    final Color activeBorder = const Color(0x3300F0FF);
    final Color inactiveColor = Colors.white.withOpacity(0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(100.0),
          border: Border.all(
            color: isSelected ? activeBorder : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(100.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(100.0),
            onTap: onTap,
            child: Container(
              height: 44.0,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18.0,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
