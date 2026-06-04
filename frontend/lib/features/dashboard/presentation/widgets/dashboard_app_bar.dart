import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/features/auth/models/user_model.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String pageLabel;
  final bool isTablet;
  final String? activeBarId;
  final String activeView;
  final String role;
  final UserModel user;
  final VoidCallback onBackPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onSelectBarPressed;

  const DashboardAppBar({
    super.key,
    required this.pageLabel,
    required this.isTablet,
    required this.activeBarId,
    required this.activeView,
    required this.role,
    required this.user,
    required this.onBackPressed,
    required this.onProfilePressed,
    required this.onSelectBarPressed,
  });

  @override
  Size get preferredSize => Size.fromHeight(isTablet ? 72.0 : 56.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget leadingWidget;
    if (isTablet) {
      leadingWidget = const Padding(
        padding: EdgeInsets.only(left: 24.0),
        child: Icon(Icons.blur_on, color: Color(0xFF00F0FF), size: 28.0),
      );
    } else {
      final bool isDeepView = activeView == 'perfil' || activeView == 'config';
      if (isDeepView) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F0FF)),
          onPressed: onBackPressed,
        );
      } else {
        leadingWidget = IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF00F0FF)),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }
    }

    List<Widget> actionsList = [];

    // Acción 2: Monitoreo en vivo de comisiones acumuladas y WebSocket para Damas
    if (role == 'DAMA' && activeView == 'comis') {
      // Indicador WebSocket
      actionsList.add(
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0x1A00F0FF),
              borderRadius: BorderRadius.circular(100.0),
              border: Border.all(color: const Color(0x3300F0FF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00F0FF),
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  'REALTIME',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF00F0FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      actionsList.add(const SizedBox(width: 8.0));

      // Indicador de Ganancias Acumuladas
      actionsList.add(
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0x1AFFB1C3),
              borderRadius: BorderRadius.circular(100.0),
              border: Border.all(color: const Color(0x33FFB1C3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_outlined, color: Color(0xFFFFB1C3), size: 13.0),
                const SizedBox(width: 6.0),
                Text(
                  '150.00 Bs',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFFFB1C3),
                    fontWeight: FontWeight.bold,
                    fontSize: 9.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      actionsList.add(const SizedBox(width: 12.0));
    }

    // Acción 3: Botón de cambio rápido de sucursal para SuperAdmins
    if (role == 'SUPERADMIN') {
      actionsList.add(
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.swap_horiz, size: 14.0, color: Color(0xFF00F0FF)),
            label: Text(
              activeBarId != null ? 'CAMBIAR BAR' : 'BARES',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.0,
                color: const Color(0xFF00F0FF),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              side: const BorderSide(color: Color(0x4D00F0FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100.0),
              ),
            ),
            onPressed: onSelectBarPressed,
          ),
        ),
      );
      actionsList.add(const SizedBox(width: 12.0));
    }

    // Acción 4: Foto de perfil premium en la esquina superior derecha (Móvil)
    if (!isTablet) {
      actionsList.add(
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: InkWell(
              onTap: onProfilePressed,
              borderRadius: BorderRadius.circular(100.0),
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x3300F0FF),
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100.0),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBZZ4F3uxeKXlMSjT5dTb1O4_BTJuDlobMGJCsqzM_uclGpddIG1PoFe-ii5WY95o6-UbkutIhovD6rNMn-Yeq0BH9OJUet_BXiwV0AICeKlwpujiO_XFxYnVuCfNdrk1lasqCUyWhonZnODKafZDkpzxmUNyGoKPyZo7zMxLqhcaNnRIgINDnP5WjuhxdbwpvaiPVSK842ts9aS8GphuRhQB4reNSPcZLIz4YV4c_HPg-0Cj5n50esRHFSYrRtQQucvQXq2pCKA1c',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, color: Color(0xFF00F0FF), size: 16.0);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Add static notifications/sync elements in Tablet
    if (isTablet) {
      actionsList.add(
        IconButton(
          icon: const Icon(Icons.sync, size: 20.0),
          color: theme.colorScheme.onSurfaceVariant,
          onPressed: () {},
        ),
      );
      actionsList.add(
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20.0),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: () {},
            ),
            Positioned(
              top: 12.0,
              right: 12.0,
              child: Container(
                width: 7.0,
                height: 7.0,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFB4AB),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
      actionsList.add(const SizedBox(width: 8.0));
      actionsList.add(
        Container(
          width: 1.0,
          height: 24.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          color: Colors.white.withOpacity(0.08),
        ),
      );
      actionsList.add(const SizedBox(width: 8.0));
      actionsList.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ESTADO: ',
              style: GoogleFonts.plusJakartaSans(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0x1A00F0FF),
                borderRadius: BorderRadius.circular(100.0),
                border: Border.all(color: const Color(0x3300F0FF)),
              ),
              child: Text(
                'EN VIVO',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF00F0FF),
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
      actionsList.add(const SizedBox(width: 24.0));
    }

    return AppBar(
      leading: leadingWidget,
      leadingWidth: isTablet ? 64.0 : 56.0,
      automaticallyImplyLeading: false,
      titleSpacing: isTablet ? 16.0 : 0.0,
      title: isTablet
          ? Row(
              children: [
                Text(
                  'Neon Management',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 22.0,
                    color: const Color(0xFFDBFCFF),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 24.0),
                // Search Input Bar to match mockup
                Container(
                  height: 38.0,
                  width: 240.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2024),
                    borderRadius: BorderRadius.circular(100.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                        size: 16.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar mesas, pedidos...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Text(
              pageLabel,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 20.0,
                color: const Color(0xFF00F0FF),
                letterSpacing: pageLabel == 'Gestobar' ? -0.8 : -0.3,
                height: 1.0,
              ),
            ),
      actions: actionsList,
      elevation: 0,
      toolbarHeight: isTablet ? 72.0 : 56.0,
      backgroundColor: const Color(0xFF111317),
      shape: Border(
        bottom: BorderSide(
          color: Colors.white.withOpacity(0.06),
          width: 1.0,
        ),
      ),
    );
  }
}
