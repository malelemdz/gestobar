import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gestobar/features/auth/providers/auth_provider.dart';
import 'package:gestobar/features/auth/providers/auth_state.dart';
import 'package:gestobar/features/auth/presentation/perfil_page.dart';
import 'package:gestobar/features/admin/providers/bar_provider.dart';
import 'package:gestobar/features/admin/presentation/auditoria_page.dart';
import 'package:gestobar/features/admin/presentation/config_page.dart';
import 'package:gestobar/features/pos/presentation/pos_page.dart';
import 'package:gestobar/features/caja/presentation/caja_page.dart';
import 'package:gestobar/features/menu_publico/presentation/menu_page.dart';
import 'package:gestobar/features/staff/presentation/staff_page.dart';
import 'package:gestobar/features/damas/presentation/dama_page.dart';
import 'package:gestobar/features/splash/presentation/splash_screen.dart';
import 'package:gestobar/features/analytics/presentation/analytics_page.dart';

import 'dashboard_page.dart';
import 'utils/navigation_helper.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/dashboard_drawer.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/dashboard_bottom_bar.dart';
import 'dialogs/about_dialog.dart';
import 'dialogs/logout_confirmation_dialog.dart';

/// Provider global para controlar la vista activa del sistema (Soporta navegación ilimitada y profunda)
final activeViewProvider = StateProvider<String>((ref) => 'dash');

class MainDashboardView extends ConsumerWidget {
  const MainDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final activeView = ref.watch(activeViewProvider);
    final activeBarId = authState.activeBarId;

    final barState = ref.watch(currentBarProvider);
    final String barName = barState.when(
      data: (bar) => bar.nombre,
      loading: () => 'Cargando...',
      error: (_, __) => 'Gestobar',
    );

    final String role = user.rolNombre.toUpperCase();

    // auto-corrección: asegurar que la vista seleccionada sea permitida para el rol
    final List<String> allowedViews = NavigationHelper.getAllowedViewsForRole(role);
    if (!allowedViews.contains(activeView)) {
      final String defaultView = NavigationHelper.getDefaultViewForRole(role);
      Future.microtask(() => ref.read(activeViewProvider.notifier).state = defaultView);
      return const PremiumSplashScreen();
    }

    final List<Map<String, dynamic>> navItems = NavigationHelper.getNavItemsForRole(role);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth >= 800;

          if (isTablet) {
            // ==========================================
            // LAYOUT TABLET / PC: Sidebar Lateral Fijo
            // ==========================================
            return Row(
              children: [
                DashboardSidebar(
                  barName: barName,
                  activeBarId: activeBarId,
                  role: role,
                  user: user,
                  navItems: navItems,
                  activeView: activeView,
                  onViewChanged: (view) {
                    ref.read(activeViewProvider.notifier).state = view;
                  },
                  onLogout: () => _showLogoutDialog(context, ref),
                  onAboutTap: () => _showAboutDialog(context),
                ),
                Expanded(
                  child: Scaffold(
                    appBar: DashboardAppBar(
                      pageLabel: NavigationHelper.getTitleForView(activeView),
                      isTablet: true,
                      activeBarId: activeBarId,
                      activeView: activeView,
                      role: role,
                      user: user,
                      onBackPressed: () {
                        ref.read(activeViewProvider.notifier).state = NavigationHelper.getDefaultViewForRole(role);
                      },
                      onProfilePressed: () {
                        ref.read(activeViewProvider.notifier).state = 'perfil';
                      },
                      onSelectBarPressed: () {
                        ref.read(authProvider.notifier).selectBar(null);
                      },
                    ),
                    body: _buildBodyForView(activeView),
                  ),
                ),
              ],
            );
          } else {
            // ==========================================
            // LAYOUT MÓVIL: Drawer + Bottom Bar
            // ==========================================
            final showBottomBar = navItems.any((item) => item['view'] == activeView);

            return Scaffold(
              drawer: DashboardDrawer(
                barName: barName,
                activeBarId: activeBarId,
                role: role,
                user: user,
                navItems: navItems,
                activeView: activeView,
                onViewChanged: (view) {
                  ref.read(activeViewProvider.notifier).state = view;
                },
                onLogout: () => _showLogoutDialog(context, ref),
                onAboutTap: () => _showAboutDialog(context),
              ),
              appBar: DashboardAppBar(
                pageLabel: NavigationHelper.getTitleForView(activeView),
                isTablet: false,
                activeBarId: activeBarId,
                activeView: activeView,
                role: role,
                user: user,
                onBackPressed: () {
                  ref.read(activeViewProvider.notifier).state = NavigationHelper.getDefaultViewForRole(role);
                },
                onProfilePressed: () {
                  ref.read(activeViewProvider.notifier).state = 'perfil';
                },
                onSelectBarPressed: () {
                  ref.read(authProvider.notifier).selectBar(null);
                },
              ),
              body: _buildBodyForView(activeView),
              bottomNavigationBar: showBottomBar && navItems.length > 1
                  ? DashboardBottomBar(
                      navItems: navItems,
                      activeView: activeView,
                      onViewChanged: (view) {
                        ref.read(activeViewProvider.notifier).state = view;
                      },
                    )
                  : null,
            );
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const LogoutConfirmationDialog();
      },
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(authProvider.notifier).logout();
      }
    });
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AboutDialogWidget();
      },
    );
  }

  Widget _buildBodyForView(String activeView) {
    switch (activeView) {
      case 'dash':
        return const DashboardPage();
      case 'pos':
        return const PosPage();
      case 'caja':
        return const CajaPage();
      case 'menu':
        return const MenuPage();
      case 'staff':
        return const StaffPage();
      case 'audit':
        return const AuditoriaPage();
      case 'analytics':
        return const AnalyticsPage();
      case 'config':
        return const ConfigPage();
      case 'perfil':
        return const PerfilPage();
      case 'comis':
        return const DamaPage();
      default:
        return const DashboardPage();
    }
  }
}
