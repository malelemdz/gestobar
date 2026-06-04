import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestobar/features/auth/providers/auth_provider.dart';
import 'package:gestobar/features/auth/providers/auth_state.dart';
import 'package:gestobar/features/admin/providers/bar_provider.dart';
import 'widgets/dashboard_session_card.dart';
import 'widgets/dashboard_bento_item.dart';
import 'main_dashboard_view.dart'; // Para activeViewProvider

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final barState = ref.watch(currentBarProvider);

    final String barName = barState.when(
      data: (bar) => bar.nombre,
      loading: () => 'Cargando...',
      error: (_, __) => 'Error al cargar',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Tarjeta Premium de Sesión Activa (Liquid Modernist Style)
          DashboardSessionCard(
            user: user,
            activeBarId: authState.activeBarId,
            barName: barName,
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
              DashboardBentoItem(
                icon: Icons.point_of_sale,
                title: 'POS Ventas',
                subtitle: 'Ir a facturación',
                color: const Color(0xFF00F0FF),
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'pos';
                },
              ),
              DashboardBentoItem(
                icon: Icons.payments,
                title: 'Caja',
                subtitle: 'Control de turnos',
                color: const Color(0xFFFFB1C3),
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'caja';
                },
              ),
              DashboardBentoItem(
                icon: Icons.local_bar,
                title: 'Menú',
                subtitle: 'Editar catálogo',
                color: const Color(0xFF7000FF),
                onTap: () {
                  ref.read(activeViewProvider.notifier).state = 'menu';
                },
              ),
              DashboardBentoItem(
                icon: Icons.people_alt,
                title: 'Staff',
                subtitle: 'Personal y roles',
                color: const Color(0xFFDBFCFF),
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
}
