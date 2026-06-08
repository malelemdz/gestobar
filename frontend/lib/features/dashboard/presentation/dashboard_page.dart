import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/core/widgets/shimmer_placeholder.dart';
import 'package:gestobar/features/auth/providers/auth_provider.dart';
import 'package:gestobar/features/auth/providers/auth_state.dart';
import 'package:gestobar/features/admin/providers/bar_provider.dart';
import 'package:gestobar/features/caja/providers/caja_provider.dart'; // currency Providers
import 'widgets/dashboard_session_card.dart';
import 'widgets/dashboard_bento_item.dart';
import 'main_dashboard_view.dart'; // activeViewProvider
import '../../admin/presentation/widgets/auditoria_log_card.dart';
import '../../admin/presentation/dialogs/log_detail_bottom_sheet.dart';
import '../../admin/providers/auditoria_recent_provider.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../analytics/data/models/analytics_resumen_model.dart';
import 'utils/navigation_helper.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  String _getMaxSaleDay(List<DailySalesModel> trend) {
    if (trend.isEmpty) return 'Sin datos';
    DailySalesModel maxItem = trend.first;
    for (final item in trend) {
      if (item.total > maxItem.total) {
        maxItem = item;
      }
    }
    if (maxItem.total == 0) return 'Sin datos';
    try {
      final date = DateTime.parse(maxItem.fecha);
      final dayName = DateFormat('EEEE', 'es').format(date);
      return dayName[0].toUpperCase() + dayName.substring(1);
    } catch (_) {
      return 'Sin datos';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final barState = ref.watch(currentBarProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final barTimezone = ref.watch(barTimezoneProvider);

    final String barName = barState.when(
      data: (bar) => bar.nombre,
      loading: () => 'Cargando...',
      error: (_, __) => 'Error al cargar',
    );

    // 1. Obtener la lista de vistas autorizadas según el rol actual
    final allowedViews = NavigationHelper.getAllowedViewsForRole(user.rolNombre);
    final bool canSeeAudit = allowedViews.contains('audit');
    final bool canSeeAnalytics = allowedViews.contains('analytics');

    // 2. Cargar datos de estadísticas y auditoría si el usuario tiene permiso
    final AsyncValue<AnalyticsResumenModel>? statsAsync =
        canSeeAnalytics ? ref.watch(analyticsResumenProvider) : null;
    final AsyncValue<List<dynamic>>? recentAuditAsync =
        canSeeAudit ? ref.watch(recentAuditoriaProvider) : null;

    // 3. Filtrar los Bento Items de accesos rápidos permitidos para el rol
    final List<Widget> allowedBentoItems = [];

    if (allowedViews.contains('pos')) {
      allowedBentoItems.add(
        DashboardBentoItem(
          icon: Icons.point_of_sale,
          title: 'POS Ventas',
          subtitle: 'Ir a facturación',
          color: const Color(0xFF00F0FF),
          onTap: () {
            ref.read(activeViewProvider.notifier).state = 'pos';
          },
        ),
      );
    }

    if (allowedViews.contains('caja')) {
      allowedBentoItems.add(
        DashboardBentoItem(
          icon: Icons.payments,
          title: 'Caja',
          subtitle: 'Control de turnos',
          color: const Color(0xFFFFB1C3),
          onTap: () {
            ref.read(activeViewProvider.notifier).state = 'caja';
          },
        ),
      );
    }

    if (allowedViews.contains('menu')) {
      allowedBentoItems.add(
        DashboardBentoItem(
          icon: Icons.local_bar,
          title: 'Menú',
          subtitle: 'Editar catálogo',
          color: const Color(0xFF7000FF),
          onTap: () {
            ref.read(activeViewProvider.notifier).state = 'menu';
          },
        ),
      );
    }

    if (allowedViews.contains('staff')) {
      allowedBentoItems.add(
        DashboardBentoItem(
          icon: Icons.people_alt,
          title: 'Staff',
          subtitle: 'Personal y roles',
          color: const Color(0xFFDBFCFF),
          onTap: () {
            ref.read(activeViewProvider.notifier).state = 'staff';
          },
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      physics: const BouncingScrollPhysics(),
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

          // 2. Grilla Bento de Accesos Rápidos Autorizados
          if (allowedBentoItems.isNotEmpty) ...[
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width >= 750 ? 4 : 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: MediaQuery.of(context).size.width >= 750 ? 1.4 : 1.3,
              children: allowedBentoItems,
            ),
            const SizedBox(height: 28.0),
          ],

          // 3. SECCIÓN: ESTADÍSTICAS RÁPIDAS (Solo si el rol tiene acceso)
          if (canSeeAnalytics && statsAsync != null) ...[
            Text(
              'Estadísticas Rápidas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12.0),
            statsAsync.when(
              loading: () => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width >= 750 ? 4 : 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: MediaQuery.of(context).size.width >= 750 ? 1.4 : 1.3,
                children: List.generate(
                  4,
                  (index) => ShimmerPlaceholder(
                    width: double.infinity,
                    height: 100,
                    borderRadius: BorderRadius.circular(32.0),
                  ),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.liquidSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: AppTheme.colorDanger.withOpacity(0.2)),
                ),
                child: Text(
                  'No se pudieron cargar las estadísticas de resumen rápido.',
                  style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (resumen) {
                final maxDayStr = _getMaxSaleDay(resumen.ventasDiarias);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width >= 750 ? 4 : 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: MediaQuery.of(context).size.width >= 750 ? 1.4 : 1.3,
                  children: [
                    DashboardBentoItem(
                      icon: Icons.monetization_on_outlined,
                      title: '${resumen.ingresosTotales.toStringAsFixed(2)} $currencySymbol',
                      subtitle: 'Ingresos Totales',
                      color: const Color(0xFF00F0FF),
                      onTap: () {
                        ref.read(analyticsTabProvider.notifier).state = 0; // Tab Resumen
                        ref.read(activeViewProvider.notifier).state = 'analytics';
                      },
                    ),
                    DashboardBentoItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: '${resumen.ingresoNetoEstimado.toStringAsFixed(2)} $currencySymbol',
                      subtitle: 'Ingreso Neto Est.',
                      color: const Color(0xFFE040FB),
                      onTap: () {
                        ref.read(analyticsTabProvider.notifier).state = 0; // Tab Resumen
                        ref.read(activeViewProvider.notifier).state = 'analytics';
                      },
                    ),
                    DashboardBentoItem(
                      icon: Icons.trending_up_rounded,
                      title: maxDayStr,
                      subtitle: 'Picos de Venta (Día)',
                      color: const Color(0xFFFFB1C3),
                      onTap: () {
                        ref.read(analyticsTabProvider.notifier).state = 1; // Tab Ventas & Picos
                        ref.read(activeViewProvider.notifier).state = 'analytics';
                      },
                    ),
                    DashboardBentoItem(
                      icon: Icons.shopping_bag_outlined,
                      title: '${resumen.cantidadVentas} ordenes',
                      subtitle: 'Cantidad Ventas',
                      color: const Color(0xFFDBFCFF),
                      onTap: () {
                        ref.read(analyticsTabProvider.notifier).state = 0; // Tab Resumen
                        ref.read(activeViewProvider.notifier).state = 'analytics';
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28.0),
          ],

          // 4. SECCIÓN: ACTIVIDAD RECIENTE (Solo si el rol tiene acceso)
          if (canSeeAudit && recentAuditAsync != null) ...[
            Text(
              'Actividad Reciente',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12.0),
            recentAuditAsync.when(
              loading: () => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ShimmerPlaceholder(
                    width: double.infinity,
                    height: 110,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppTheme.liquidSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppTheme.colorDanger.withOpacity(0.2)),
                ),
                child: Text(
                  'No se pudo conectar con los registros de auditoría en vivo.',
                  style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    decoration: BoxDecoration(
                      color: AppTheme.liquidSurfaceContainerLow,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Center(
                      child: Text(
                        'No hay registros de actividad recientes',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return InkWell(
                      onTap: () => showLogDetail(context, log, currencyIso, currencySymbol, barTimezone),
                      borderRadius: BorderRadius.circular(16.0),
                      child: AuditoriaLogCard(
                        log: log,
                        currencyIso: currencyIso,
                        currencySymbol: currencySymbol,
                        barTimezone: barTimezone,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
