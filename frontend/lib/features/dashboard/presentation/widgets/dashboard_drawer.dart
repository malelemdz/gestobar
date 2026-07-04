import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/features/auth/models/user_model.dart';

class DashboardDrawer extends StatelessWidget {
  final String barName;
  final String? activeBarId;
  final String role;
  final UserModel user;
  final List<Map<String, dynamic>> navItems;
  final String activeView;
  final void Function(String) onViewChanged;
  final VoidCallback onLogout;
  final VoidCallback onAboutTap;

  const DashboardDrawer({
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
    final String activeBarName = activeBarId != null ? barName : 'Consola Global';

    return Drawer(
      backgroundColor: const Color(0xFF1E2024),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sleek Drawer Header with premium Logo Box and branding
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 80.0, 24.0, 36.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Gestobar',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 22.0,
                              color: const Color(0xFFDBFCFF),
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            activeBarName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11.0,
                              color: const Color(0xFF00F0FF),
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.06), height: 1.0),
          const SizedBox(height: 16.0),

          // Dynamic operational pages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: navItems.where((i) => i['view'] != 'perfil').length,
              itemBuilder: (context, index) {
                final filtered = navItems.where((i) => i['view'] != 'perfil').toList();
                final item = filtered[index];
                final String viewId = item['view'] as String;
                final bool isSelected = activeView == viewId;
 
                return _buildSidebarNavItem(
                  context: context,
                  icon: isSelected ? item['icon_active'] as IconData : item['icon'] as IconData,
                  label: item['label'] as String,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    onViewChanged(viewId);
                  },
                );
              },
            ),
          ),

          // Secondary and support actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              children: [
                Divider(color: Colors.white.withOpacity(0.06), height: 1.0),
                const SizedBox(height: 8.0),

                // Profile internal page link
                _buildSidebarBottomItem(
                  context: context,
                  icon: Icons.person_outline,
                  label: 'Mi Perfil',
                  isSelected: activeView == 'perfil',
                  onTap: () {
                    Navigator.pop(context);
                    onViewChanged('perfil');
                  },
                ),

                // Config page link for admins
                if (role == 'ADMIN' || (role == 'SUPERADMIN' && activeBarId != null))
                  _buildSidebarBottomItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    label: 'Configuración',
                    isSelected: activeView == 'config',
                    onTap: () {
                      Navigator.pop(context);
                      onViewChanged('config');
                    },
                  ),

                // Support modal trigger
                _buildSidebarBottomItem(
                  context: context,
                  icon: Icons.info_outline,
                  label: 'Acerca de',
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context);
                    onAboutTap();
                  },
                ),

                // Modernist primary CTA Button now functioning as "CERRAR SESIÓN"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Container(
                    height: 48.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF),
                      borderRadius: BorderRadius.circular(100.0),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withOpacity(0.15),
                          blurRadius: 16.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100.0),
                        onTap: () {
                          Navigator.pop(context);
                          onLogout();
                        },
                        child: Center(
                          child: Text(
                            (role == 'SUPERADMIN' && activeBarId != null)
                                ? 'SALIR DEL BAR'
                                : 'CERRAR SESIÓN',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00363A),
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
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
