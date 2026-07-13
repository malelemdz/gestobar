import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/features/auth/models/user_model.dart';
import 'package:gestobar/core/constants/api_constants.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/features/admin/providers/bar_provider.dart';

class DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Widget? leadingWidget;
    if (isTablet) {
      leadingWidget = null;
    } else {
      final bool isDeepView = activeView == 'perfil' || activeView == 'config';
      if (isDeepView) {
        leadingWidget = IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.liquidPrimary),
          onPressed: onBackPressed,
        );
      } else {
        leadingWidget = IconButton(
          icon: Icon(Icons.menu, color: AppTheme.liquidPrimary),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      }
    }

    List<Widget> actionsList = [];

    // Obtener logo del bar si está en una sucursal
    String? barLogoUrl;
    if (activeBarId != null) {
      final barState = ref.watch(currentBarProvider);
      barLogoUrl = barState.maybeWhen(
        data: (bar) => bar.logoUrl,
        orElse: () => null,
      );
    }

    // Acción: Foto de perfil o Logo de sucursal en la esquina superior derecha
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
                  color: AppTheme.liquidPrimary.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100.0),
                child: (activeBarId != null && barLogoUrl != null && barLogoUrl.isNotEmpty)
                    ? Image.network(
                        ApiConstants.resolveImageUrl(barLogoUrl) ?? barLogoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                                ? Image.network(
                                    ApiConstants.resolveImageUrl(user.fotoUrl)!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _buildInitialsPlaceholder(user),
                                  )
                                : _buildInitialsPlaceholder(user),
                      )
                    : (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                        ? Image.network(
                            ApiConstants.resolveImageUrl(user.fotoUrl)!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitialsPlaceholder(user),
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
      leadingWidth: isTablet ? 0.0 : 56.0,
      automaticallyImplyLeading: false,
      titleSpacing: isTablet ? 24.0 : 0.0,
      title: Text(
        pageLabel,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          fontSize: 20.0,
          color: AppTheme.liquidPrimary,
          height: 1.0,
        ),
      ),
      actions: actionsList,
      elevation: 0,
      toolbarHeight: isTablet ? 72.0 : 56.0,
      backgroundColor: AppTheme.liquidBg,
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
      color: AppTheme.liquidSurface,
      alignment: Alignment.center,
      child: Text(
        (user.nombre.isNotEmpty ? user.nombre[0] : 'U').toUpperCase(),
        style: GoogleFonts.poppins(
          color: AppTheme.liquidPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
    );
  }
}
