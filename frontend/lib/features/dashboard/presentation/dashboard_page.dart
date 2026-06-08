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
import '../../analytics/data/models/product_ranking_model.dart';
import '../../pos/providers/catalog_provider.dart';
import '../../caja/providers/ventas_activas_provider.dart';
import 'utils/navigation_helper.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Widget _buildShimmerItem() {
    return ShimmerPlaceholder(
      width: double.infinity,
      height: 100,
      borderRadius: BorderRadius.circular(24.0),
    );
  }

  Widget _buildErrorItem(String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.liquidSurfaceContainerLow,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppTheme.colorDanger.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          'Error $label',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.redAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

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
    final AsyncValue<List<ProductRankingModel>>? rankingAsync =
        canSeeAnalytics ? ref.watch(analyticsProductRankingProvider) : null;
    final productsAsync = ref.watch(productsProvider);
    final cajaState = ref.watch(cajaStateProvider);
    final ventasState = ref.watch(ventasActivasProvider);
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
          const SizedBox(height: 16.0),

          // 2. Grilla Bento de Accesos Rápidos Autorizados
          if (allowedBentoItems.isNotEmpty) ...[
            Text(
              'Accesos Directos',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10.0),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisCount: MediaQuery.of(context).size.width >= 750 ? 4 : 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: MediaQuery.of(context).size.width >= 750 ? 1.4 : 1.3,
              children: allowedBentoItems,
            ),
            const SizedBox(height: 16.0),
          ],

          // 3. SECCIÓN: ESTADÍSTICAS RÁPIDAS (Solo si el rol tiene acceso)
          if (canSeeAnalytics && statsAsync != null && rankingAsync != null) ...[
            Text(
              'Estadísticas Rápidas',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10.0),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisCount: MediaQuery.of(context).size.width >= 750 ? 4 : 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: MediaQuery.of(context).size.width >= 750 ? 1.4 : 1.3,
              children: [
                // 1. PRODUCTOS EN MENÚ
                productsAsync.when(
                  data: (list) => DashboardBentoItem(
                    icon: Icons.inventory_2_outlined,
                    title: '${list.length} Items',
                    subtitle: 'Productos en Menú',
                    color: const Color(0xFF00F0FF),
                    onTap: () {
                      ref.read(activeViewProvider.notifier).state = 'menu';
                    },
                  ),
                  loading: () => _buildShimmerItem(),
                  error: (_, __) => _buildErrorItem('Productos'),
                ),

                // 2. ACTIVIDAD / MOVIMIENTOS DEL TURNO
                cajaState.when(
                  data: (est) {
                    final int totalMov = est.abierta
                        ? (est.caja!.movimientos.length + ventasState.ventas.length)
                        : 0;
                    return DashboardBentoItem(
                      icon: Icons.swap_vert_outlined,
                      title: est.abierta ? '$totalMov mov.' : 'Caja Cerrada',
                      subtitle: 'Movimientos del Turno',
                      color: const Color(0xFFE040FB),
                      onTap: () {
                        ref.read(activeViewProvider.notifier).state = 'caja';
                      },
                    );
                  },
                  loading: () => _buildShimmerItem(),
                  error: (_, __) => _buildErrorItem('Caja'),
                ),

                // 3. DÍA MÁS VENDIDO (ÚLTIMOS 30 DÍAS)
                statsAsync.when(
                  data: (resumen) {
                    final maxDayStr = _getMaxSaleDay(resumen.ventasDiarias);
                    return DashboardBentoItem(
                      icon: Icons.trending_up_rounded,
                      title: maxDayStr,
                      subtitle: 'Día Más Vendido (30d)',
                      color: const Color(0xFFFFB1C3),
                      onTap: () {
                        ref.read(analyticsTabProvider.notifier).state = 1; // Tab Tendencias & Picos
                        ref.read(activeViewProvider.notifier).state = 'analytics';
                      },
                    );
                  },
                  loading: () => _buildShimmerItem(),
                  error: (_, __) => _buildErrorItem('Picos'),
                ),

                // 4. PRODUCTO TOP (ÚLTIMOS 30 DÍAS)
                rankingAsync.when(
                  data: (list) {
                    final topProduct = list.isNotEmpty ? list.first.productoNombre : 'Sin datos';
                    return DashboardBentoItem(
                      icon: Icons.local_bar_outlined,
                      title: topProduct,
                      subtitle: 'Producto Top (30d)',
                      color: const Color(0xFFDBFCFF),
                      onTap: () {
                        ref.read(analyticsTabProvider.notifier).state = 2; // Tab Productos
                        ref.read(activeViewProvider.notifier).state = 'analytics';
                      },
                    );
                  },
                  loading: () => _buildShimmerItem(),
                  error: (_, __) => _buildErrorItem('Top Prod.'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
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
            const SizedBox(height: 10.0),
            recentAuditAsync.when(
              loading: () => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
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
                  padding: EdgeInsets.zero,
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
