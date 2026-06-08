import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/core/widgets/shimmer_placeholder.dart';
import 'package:gestobar/features/caja/providers/caja_provider.dart'; // currency Providers
import 'package:gestobar/features/admin/providers/bar_provider.dart';
import 'package:gestobar/features/admin/presentation/widgets/custom_date_range_picker.dart';
import 'package:gestobar/core/utils/currency_helper.dart';
import '../providers/analytics_provider.dart';
import 'widgets/sales_trend_chart.dart';
import 'widgets/payment_methods_chart.dart';
import 'widgets/product_ranking_list.dart';
import 'widgets/dama_ranking_list.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTab = ref.watch(analyticsTabProvider);
    final activeFilter = ref.watch(analyticsFilterProvider);
    final dateRange = ref.watch(analyticsDateRangeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final barAsync = ref.watch(currentBarProvider);
    final bool showStaffDamas = barAsync.maybeWhen(
      data: (bar) => bar.moduloDamasActivo,
      orElse: () => false,
    );

    if (!showStaffDamas && activeTab == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(analyticsTabProvider.notifier).state = 0;
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background.withOpacity(0.4),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector de Rango de Fechas (Filtros superiores)
              _buildFilterBar(context, activeFilter, dateRange),
              const SizedBox(height: 12.0),

              // 2. Selector de Pestañas Bento
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181A1E),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(0, 'RESUMEN', Icons.analytics_outlined),
                        _buildTabButton(1, 'TENDENCIAS', Icons.trending_up),
                        _buildTabButton(2, 'PRODUCTOS', Icons.local_bar_outlined),
                        if (showStaffDamas)
                          _buildTabButton(3, 'DAMAS', Icons.people_outline),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Cuerpo de la Vista Activa
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildActiveView(activeTab, currencySymbol, currencyIso, showStaffDamas),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    AnalyticsDateFilter activeFilter,
    DateTimeRange dateRange,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
      child: Row(
        children: [
          _buildFilterChip(
            label: '7 Días',
            isSelected: activeFilter == AnalyticsDateFilter.last7Days,
            onTap: () {
              ref.read(analyticsFilterProvider.notifier).state = AnalyticsDateFilter.last7Days;
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '30 Días',
            isSelected: activeFilter == AnalyticsDateFilter.last30Days,
            onTap: () {
              ref.read(analyticsFilterProvider.notifier).state = AnalyticsDateFilter.last30Days;
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '90 Días',
            isSelected: activeFilter == AnalyticsDateFilter.last90Days,
            onTap: () {
              ref.read(analyticsFilterProvider.notifier).state = AnalyticsDateFilter.last90Days;
            },
          ),
          const SizedBox(width: 8),
          _buildCustomFilterChip(context, activeFilter, dateRange),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.liquidSecondary, AppTheme.liquidPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppTheme.liquidSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? AppTheme.liquidPrimary.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFilterChip(
    BuildContext context,
    AnalyticsDateFilter activeFilter,
    DateTimeRange dateRange,
  ) {
    final bool isSelected = activeFilter == AnalyticsDateFilter.custom;
    final format = DateFormat('dd MMM');
    final label = isSelected
        ? '${format.format(dateRange.start)} - ${format.format(dateRange.end)}'
        : 'Personalizado';

    return InkWell(
      onTap: () => _selectCustomDateRange(context, dateRange),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.liquidSecondary, AppTheme.liquidPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppTheme.liquidSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? AppTheme.liquidPrimary.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.calendar_today_outlined,
              size: 12,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomDateRange(BuildContext context, DateTimeRange currentRange) async {
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: AppTheme.liquidSurfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return CustomDateRangePicker(initialRange: currentRange);
      },
    );

    if (picked != null) {
      ref.read(analyticsFilterProvider.notifier).state = AnalyticsDateFilter.custom;
      ref.read(analyticsDateRangeProvider.notifier).state = picked;
    }
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final activeTab = ref.watch(analyticsTabProvider);
    final bool isActive = activeTab == index;

    return GestureDetector(
      onTap: () {
        ref.read(analyticsTabProvider.notifier).state = index;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00F0FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF00F0FF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? Colors.black : Colors.white30,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isActive ? Colors.black : Colors.white30,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveView(int activeTab, String currencySymbol, String currencyIso, bool showStaffDamas) {
    switch (activeTab) {
      case 0:
        return _buildResumenTab(currencySymbol, currencyIso);
      case 1:
        return _buildPicosTab();
      case 2:
        return const ProductRankingList();
      case 3:
        return showStaffDamas ? const DamaRankingList() : _buildResumenTab(currencySymbol, currencyIso);
      default:
        return _buildResumenTab(currencySymbol, currencyIso);
    }
  }

  Widget _buildResumenTab(String currencySymbol, String currencyIso) {
    final resumenAsync = ref.watch(analyticsResumenProvider);

    return resumenAsync.when(
      loading: () => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          Row(
            children: [
              Expanded(
                child: ShimmerPlaceholder(width: double.infinity, height: 110, borderRadius: BorderRadius.circular(16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ShimmerPlaceholder(width: double.infinity, height: 110, borderRadius: BorderRadius.circular(16)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ShimmerPlaceholder(width: double.infinity, height: 110, borderRadius: BorderRadius.circular(16)),
          const SizedBox(height: 12),
          ShimmerPlaceholder(width: double.infinity, height: 260, borderRadius: BorderRadius.circular(16)),
        ],
      ),
      error: (err, _) => Center(
        child: Text(
          'Error al cargar estadísticas: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (resumen) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isWide = width >= 850;

            final cardVentasTotales = _buildBentoCard(
              title: 'Ventas Totales POS',
              value: CurrencyHelper.formatWithSymbol(resumen.ingresosTotales, currencySymbol, currencyIso),
              icon: Icons.monetization_on_outlined,
              color: const Color(0xFF00F0FF),
            );

            final cardVentaNeta = _buildBentoCard(
              title: 'Venta Neta Bar',
              value: CurrencyHelper.formatWithSymbol(resumen.ingresoNetoEstimado, currencySymbol, currencyIso),
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFFE040FB),
            );

            final cardComisiones = _buildBentoCard(
              title: 'Comisiones Staff',
              value: CurrencyHelper.formatWithSymbol(resumen.comisionesPagadas, currencySymbol, currencyIso),
              icon: Icons.people_outline,
              color: const Color(0xFFFFB1C3),
            );

            final cardCantidadVentas = _buildBentoCard(
              title: 'Cantidad Ventas',
              value: '${resumen.cantidadVentas} ordenes',
              icon: Icons.shopping_bag_outlined,
              color: const Color(0xFFDBFCFF),
            );

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              physics: const BouncingScrollPhysics(),
              children: [
                if (isWide)
                  Row(
                    children: [
                      Expanded(child: cardVentasTotales),
                      const SizedBox(width: 12),
                      Expanded(child: cardVentaNeta),
                      const SizedBox(width: 12),
                      Expanded(child: cardComisiones),
                      const SizedBox(width: 12),
                      Expanded(child: cardCantidadVentas),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(child: cardVentasTotales),
                      const SizedBox(width: 12),
                      Expanded(child: cardVentaNeta),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: cardComisiones),
                      const SizedBox(width: 12),
                      Expanded(child: cardCantidadVentas),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                // Métodos de Pago Card
                PaymentMethodsChart(breakdown: resumen.desglosePagos),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPicosTab() {
    final resumenAsync = ref.watch(analyticsResumenProvider);

    return resumenAsync.when(
      loading: () => Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(color: AppTheme.liquidPrimary, strokeWidth: 2.5),
        ),
      ),
      error: (err, _) => Center(
        child: Text(
          'Error al cargar la tendencia de ventas: $err',
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
      data: (resumen) {
        return SalesTrendChart(trend: resumen.ventasDiarias);
      },
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: color, size: 18.0),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
