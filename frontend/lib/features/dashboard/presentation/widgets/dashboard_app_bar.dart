import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/features/auth/models/user_model.dart';
import 'package:gestobar/core/constants/api_constants.dart';

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



    // Acción 3: Botón de cambio rápido de sucursal removido (ahora integrado en menú lateral)

    // Acción 4: Foto de perfil premium en la esquina superior derecha (Móvil y Tablet)
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
                child: (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                    ? Image.network(
                        ApiConstants.resolveImageUrl(user.fotoUrl)!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitialsPlaceholder(user);
                        },
                      )
                    : _buildInitialsPlaceholder(user),
              ),
            ),
          ),
        ),
      ),
    );

    return AppBar(
      leading: leadingWidget,
      leadingWidth: isTablet ? 64.0 : 56.0,
      automaticallyImplyLeading: false,
      titleSpacing: isTablet ? 16.0 : 0.0,
      title: Text(
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

  Widget _buildInitialsPlaceholder(UserModel user) {
    return Container(
      color: const Color(0xFF1E2024),
      alignment: Alignment.center,
      child: Text(
        (user.nombre.isNotEmpty ? user.nombre[0] : 'U').toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF00F0FF),
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
    );
  }
}
