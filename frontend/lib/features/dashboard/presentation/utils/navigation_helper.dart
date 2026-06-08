import 'package:flutter/material.dart';

class NavigationHelper {
  static List<String> getAllowedViewsForRole(String role) {
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

  static String getDefaultViewForRole(String role) {
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

  static List<Map<String, dynamic>> getNavItemsForRole(String role) {
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
            'label': 'Comis',
            'icon': Icons.star_outline,
            'icon_active': Icons.star,
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
