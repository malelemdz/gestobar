import 'package:flutter/material.dart';

class NavigationHelper {
  static List<String> getAllowedViewsForRole(String role, {bool isGlobalMode = false}) {
    if (role.toUpperCase() == 'SUPERADMIN' && isGlobalMode) {
      return ['super_dash', 'super_bars', 'super_admins', 'super_audit', 'perfil'];
    }
    switch (role.toUpperCase()) {
      case 'SUPERADMIN':
      case 'ADMIN':
        return ['dash', 'pos', 'caja', 'menu', 'staff', 'audit', 'config', 'perfil', 'analytics'];
      case 'BARMAN':
        return ['pos', 'caja', 'perfil'];
      case 'DAMA':
        return ['comis', 'perfil'];
      default:
        return ['dash', 'perfil'];
    }
  }

  static String getDefaultViewForRole(String role, {bool isGlobalMode = false}) {
    if (role.toUpperCase() == 'SUPERADMIN' && isGlobalMode) {
      return 'super_dash';
    }
    switch (role.toUpperCase()) {
      case 'SUPERADMIN':
      case 'ADMIN':
        return 'dash';
      case 'BARMAN':
        return 'pos';
      case 'DAMA':
        return 'comis';
      default:
        return 'dash';
    }
  }

  static List<Map<String, dynamic>> getNavItemsForRole(String role, {bool isGlobalMode = false}) {
    if (role.toUpperCase() == 'SUPERADMIN' && isGlobalMode) {
      return [
        {
          'view': 'super_dash',
          'label': 'Dash',
          'icon': Icons.dashboard_outlined,
          'icon_active': Icons.dashboard,
        },
        {
          'view': 'super_bars',
          'label': 'Sucursales',
          'icon': Icons.storefront_outlined,
          'icon_active': Icons.storefront,
        },
        {
          'view': 'super_admins',
          'label': 'Admin',
          'icon': Icons.admin_panel_settings_outlined,
          'icon_active': Icons.admin_panel_settings,
        },
        {
          'view': 'super_audit',
          'label': 'Auditoría',
          'icon': Icons.security_outlined,
          'icon_active': Icons.security,
        },
      ];
    }
    switch (role.toUpperCase()) {
      case 'SUPERADMIN':
      case 'ADMIN':
        return [
          {
            'view': 'dash',
            'label': 'Dash',
            'icon': Icons.dashboard_outlined,
            'icon_active': Icons.dashboard,
          },
          {
            'view': 'pos',
            'label': 'POS',
            'icon': Icons.point_of_sale_outlined,
            'icon_active': Icons.point_of_sale,
          },
          {
            'view': 'caja',
            'label': 'Caja',
            'icon': Icons.payments_outlined,
            'icon_active': Icons.payments,
          },
          {
            'view': 'menu',
            'label': 'Menú',
            'icon': Icons.local_bar_outlined,
            'icon_active': Icons.local_bar,
          },
          {
            'view': 'staff',
            'label': 'Staff',
            'icon': Icons.people_alt_outlined,
            'icon_active': Icons.people,
          },
          {
            'view': 'analytics',
            'label': 'Analíticas',
            'icon': Icons.bar_chart_outlined,
            'icon_active': Icons.bar_chart,
          },
          {
            'view': 'audit',
            'label': 'Auditoría',
            'icon': Icons.security_outlined,
            'icon_active': Icons.security,
          },
        ];
      case 'BARMAN':
        return [
          {
            'view': 'pos',
            'label': 'POS',
            'icon': Icons.point_of_sale_outlined,
            'icon_active': Icons.point_of_sale,
          },
          {
            'view': 'caja',
            'label': 'Caja',
            'icon': Icons.payments_outlined,
            'icon_active': Icons.payments,
          },
        ];
      case 'DAMA':
        return [
          {
            'view': 'comis',
            'label': 'Comisiones',
            'icon': Icons.star_outline,
            'icon_active': Icons.star,
          },
          {
            'view': 'perfil',
            'label': 'Mi Perfil',
            'icon': Icons.person_outline,
            'icon_active': Icons.person,
          },
        ];
      default:
        return [
          {
            'view': 'dash',
            'label': 'Dash',
            'icon': Icons.dashboard_outlined,
            'icon_active': Icons.dashboard,
          },
        ];
    }
  }

  static String getTitleForView(String activeView) {
    switch (activeView) {
      case 'super_dash':
        return 'Dash';
      case 'super_audit':
        return 'Auditoría';
      case 'super_bars':
        return 'Sucursales';
      case 'super_admins':
        return 'Admin';
      case 'dash':
        return 'Dash';
      case 'analytics':
        return 'Analíticas';
      case 'pos':
        return 'POS';
      case 'caja':
        return 'Caja';
      case 'menu':
        return 'Menú';
      case 'staff':
        return 'Staff';
      case 'audit':
        return 'Auditoría';
      case 'config':
        return 'Config';
      case 'perfil':
        return 'Mi Perfil';
      case 'comis':
        return 'Comis';
      default:
        return 'Gestobar';
    }
  }
}
