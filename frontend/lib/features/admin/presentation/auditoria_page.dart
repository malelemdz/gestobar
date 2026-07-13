import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../caja/providers/caja_provider.dart';
import '../providers/auditoria_provider.dart';
import '../providers/bar_provider.dart';
import '../providers/staff_provider.dart';
import '../../auth/models/user_model.dart';
import 'dialogs/log_detail_bottom_sheet.dart';
import 'dialogs/auditoria_filter_selectors.dart';
import 'utils/auditoria_formatters.dart';
import 'widgets/auditoria_filter_capsules.dart';
import 'widgets/auditoria_log_card.dart';
import 'widgets/custom_date_range_picker.dart';

class AuditoriaPage extends ConsumerStatefulWidget {
  const AuditoriaPage({super.key});

  @override
  ConsumerState<AuditoriaPage> createState() => _AuditoriaPageState();
}

class _AuditoriaPageState extends ConsumerState<AuditoriaPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(auditoriaListProvider.notifier).loadNextPage();
    }
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(auditoriaFiltersProvider);
    DateTimeRange? initialRange;
    if (filters['fechaInicio'] != null && filters['fechaFin'] != null) {
      initialRange = DateTimeRange(
        start: DateTime.parse(filters['fechaInicio']!),
        end: DateTime.parse(filters['fechaFin']!),
      );
    }

    final picked = await CustomDateRangePicker.show(context, initialRange);

    if (picked != null) {
      ref.read(auditoriaFiltersProvider.notifier).update((state) => {
        ...state,
        'fechaInicio': DateFormat('yyyy-MM-dd').format(picked.start),
        'fechaFin': DateFormat('yyyy-MM-dd').format(picked.end),
      });
    }
  }

  Widget _buildVerticalFiltersPanel(
    BuildContext context,
    Map<String, String?> filters,
    AsyncValue<List<UserModel>> staffAsync,
  ) {
    final selectedUsuarioId = filters['usuarioId'];
    final selectedAction = filters['accion'];
    final selectedModule = filters['modulo'];
    final start = filters['fechaInicio'];
    final end = filters['fechaFin'];
    final isDateSelected = start != null && end != null;

    String userLabel = 'Todos';
    if (selectedUsuarioId != null) {
      userLabel = staffAsync.maybeWhen(
        data: (users) {
          for (final u in users) {
            if (u.id == selectedUsuarioId) return u.nombre;
          }
          return 'Usuario Sel.';
        },
        orElse: () => 'Usuario Sel.',
      );
    }

    String dateLabel = 'Todas';
    if (isDateSelected) {
      try {
        final startDt = DateTime.parse(start);
        final endDt = DateTime.parse(end);
        final format = DateFormat('dd MMM');
        dateLabel = '${format.format(startDt)} - ${format.format(endDt)}';
      } catch (_) {}
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'FILTRAR POR USUARIO',
            style: GoogleFonts.poppins(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _buildVerticalFilterItem(
            label: userLabel,
            isActive: selectedUsuarioId != null,
            onTap: () => showUserSelector(context, ref),
            onClear: () {
              ref.read(auditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'usuarioId': null,
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'FILTRAR POR ACCIÓN',
            style: GoogleFonts.poppins(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _buildVerticalFilterItem(
            label: selectedAction != null ? AuditoriaFormatters.formatAction(selectedAction) : 'Todas',
            isActive: selectedAction != null,
            onTap: () => showActionSelector(context, ref),
            onClear: () {
              ref.read(auditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'accion': null,
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'FILTRAR POR MÓDULO',
            style: GoogleFonts.poppins(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _buildVerticalFilterItem(
            label: selectedModule ?? 'Todos',
            isActive: selectedModule != null,
            onTap: () => showModuleSelector(context, ref),
            onClear: () {
              ref.read(auditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'modulo': null,
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'FILTRAR POR RANGO DE FECHAS',
            style: GoogleFonts.poppins(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _buildVerticalFilterItem(
            label: dateLabel,
            isActive: isDateSelected,
            onTap: () => _selectDateRange(context, ref),
            onClear: () {
              ref.read(auditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'fechaInicio': null,
                'fechaFin': null,
              });
            },
          ),
          const SizedBox(height: 24),
          if (selectedUsuarioId != null || selectedAction != null || selectedModule != null || isDateSelected)
            InkWell(
              onTap: () {
                ref.read(auditoriaFiltersProvider.notifier).state = {
                  'usuarioId': null,
                  'accion': null,
                  'modulo': null,
                  'fechaInicio': null,
                  'fechaFin': null,
                };
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.colorDanger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.colorDanger.withOpacity(0.3)),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_off_outlined, color: AppTheme.colorDanger, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'LIMPIAR TODOS LOS FILTROS',
                        style: GoogleFonts.poppins(
                          color: AppTheme.colorDanger,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalFilterItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.liquidPrimary.withOpacity(0.08) : const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTheme.liquidPrimary.withOpacity(0.3) : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: isActive ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (isActive)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14, color: AppTheme.colorDanger),
              )
            else
              const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auditoriaState = ref.watch(auditoriaListProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final barTimezone = ref.watch(barTimezoneProvider);
    final filters = ref.watch(auditoriaFiltersProvider);
    final staffAsync = ref.watch(staffListProvider);

    return Scaffold(
      backgroundColor: AppTheme.liquidBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTabletLandscape = constraints.maxWidth >= 720;

          if (isTabletLandscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Columna izquierda (ancho 320px): filtros fijos
                Container(
                  width: 320,
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 16),
                  child: _buildVerticalFiltersPanel(context, filters, staffAsync),
                ),
                // Standardized 1px vertical divider
                Container(
                  width: 1,
                  color: Colors.white.withOpacity(0.04),
                ),
                // Columna derecha (Expanded): listado de logs
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.liquidPrimary,
                    backgroundColor: const Color(0xFF1E2024),
                    onRefresh: () async {
                      await ref.read(auditoriaListProvider.notifier).loadInitial(silent: true);
                    },
                    child: _buildMainContent(auditoriaState, theme, currencyIso, currencySymbol, barTimezone, isTabletLandscape),
                  ),
                ),
              ],
            );
          }

          // Diseño Móvil / Portrait
          return Column(
            children: [
              // Capsule Filters Horizontal List
              const AuditoriaFilterCapsules(),
              // Log List
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.liquidPrimary,
                  backgroundColor: const Color(0xFF1E2024),
                  onRefresh: () async {
                    await ref.read(auditoriaListProvider.notifier).loadInitial(silent: true);
                  },
                  child: _buildMainContent(auditoriaState, theme, currencyIso, currencySymbol, barTimezone, isTabletLandscape),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(
    AuditoriaState state,
    ThemeData theme,
    String currencyIso,
    String currencySymbol,
    String barTimezone,
    bool isTabletLandscape,
  ) {
    Widget listWidget;

    if (state.isLoading) {
      listWidget = ListView.builder(
        padding: isTabletLandscape
            ? const EdgeInsets.fromLTRB(12, 12, 24, 16)
            : const EdgeInsets.fromLTRB(16, 0, 16, 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ShimmerPlaceholder(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      );
    } else if (state.errorMessage != null && state.logs.isEmpty) {
      listWidget = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.colorDanger.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar la auditoría',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (state.logs.isEmpty) {
      listWidget = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  'No hay registros de auditoría',
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      listWidget = ListView.builder(
        controller: _scrollController,
        padding: isTabletLandscape
            ? const EdgeInsets.fromLTRB(12, 12, 24, 16)
            : const EdgeInsets.fromLTRB(16, 0, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: state.logs.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.logs.length) {
            final log = state.logs[index];
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
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppTheme.liquidPrimary,
                  ),
                ),
              ),
            );
          }
        },
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: listWidget,
      ),
    );
  }
}
