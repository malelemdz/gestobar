import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../caja/providers/caja_provider.dart';
import '../providers/auditoria_provider.dart';
import '../providers/bar_provider.dart';
import '../../auth/models/user_model.dart';
import 'dialogs/log_detail_bottom_sheet.dart';
import 'utils/auditoria_formatters.dart';
import 'widgets/auditoria_log_card.dart';
import 'widgets/custom_date_range_picker.dart';
import 'bar_selector_view.dart';

class SuperAuditoriaPage extends ConsumerStatefulWidget {
  const SuperAuditoriaPage({super.key});

  @override
  ConsumerState<SuperAuditoriaPage> createState() => _SuperAuditoriaPageState();
}

class _SuperAuditoriaPageState extends ConsumerState<SuperAuditoriaPage> {
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
      ref.read(superAuditoriaListProvider.notifier).loadNextPage();
    }
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(superAuditoriaFiltersProvider);
    DateTimeRange? initialRange;
    if (filters['fechaInicio'] != null && filters['fechaFin'] != null) {
      initialRange = DateTimeRange(
        start: DateTime.parse(filters['fechaInicio']!),
        end: DateTime.parse(filters['fechaFin']!),
      );
    }

    final picked = await CustomDateRangePicker.show(context, initialRange);

    if (picked != null) {
      ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
        ...state,
        'fechaInicio': DateFormat('yyyy-MM-dd').format(picked.start),
        'fechaFin': DateFormat('yyyy-MM-dd').format(picked.end),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auditoriaState = ref.watch(superAuditoriaListProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final barTimezone = ref.watch(barTimezoneProvider);
    final filters = ref.watch(superAuditoriaFiltersProvider);
    final staffAsync = ref.watch(superStaffListProvider);
    final barsAsync = ref.watch(barsFutureProvider);

    final Map<String, String> barMap = {};
    barsAsync.maybeWhen(
      data: (list) {
        for (final item in list) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            final nombre = item['nombre']?.toString() ?? '';
            if (id.isNotEmpty) barMap[id] = nombre;
          }
        }
      },
      orElse: () {},
    );

    return Scaffold(
      backgroundColor: AppTheme.liquidBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTabletLandscape = constraints.maxWidth >= 720;

          if (isTabletLandscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Columna izquierda (ancho 280px): filtros fijos
                Container(
                  width: 280,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.white.withOpacity(0.03)),
                    ),
                  ),
                  child: _buildVerticalFiltersPanel(context, filters, staffAsync, barMap),
                ),
                // Columna derecha (Expanded): listado de logs
                Expanded(
                  child: RefreshIndicator(
                    color: AppTheme.liquidPrimary,
                    backgroundColor: const Color(0xFF1E2024),
                    onRefresh: () async {
                      await ref.read(superAuditoriaListProvider.notifier).loadInitial(silent: true);
                    },
                    child: _buildMainContent(auditoriaState, theme, currencyIso, currencySymbol, barTimezone, isTabletLandscape, barMap),
                  ),
                ),
              ],
            );
          }

          // Diseño Móvil / Portrait
          return Column(
            children: [
              const SizedBox(height: 8),
              const SuperAuditoriaFilterCapsules(),
              const SizedBox(height: 8),
              // Log List
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.liquidPrimary,
                  backgroundColor: const Color(0xFF1E2024),
                  onRefresh: () async {
                    await ref.read(superAuditoriaListProvider.notifier).loadInitial(silent: true);
                  },
                  child: _buildMainContent(auditoriaState, theme, currencyIso, currencySymbol, barTimezone, isTabletLandscape, barMap),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVerticalFiltersPanel(
    BuildContext context,
    Map<String, String?> filters,
    AsyncValue<List<UserModel>> staffAsync,
    Map<String, String> barMap,
  ) {
    final selectedBarId = filters['barId'];
    final selectedUsuarioId = filters['usuarioId'];
    final selectedAction = filters['accion'];
    final selectedModule = filters['modulo'];
    final start = filters['fechaInicio'];
    final end = filters['fechaFin'];
    final isDateSelected = start != null && end != null;

    String barLabel = 'Todas';
    if (selectedBarId != null) {
      barLabel = barMap[selectedBarId] ?? 'Sucursal Sel.';
    }

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
            'FILTRAR POR SUCURSAL',
            style: GoogleFonts.poppins(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _buildVerticalFilterItem(
            label: barLabel,
            isActive: selectedBarId != null,
            onTap: () => _showBarSelector(context, ref),
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'barId': null,
              });
            },
          ),
          const SizedBox(height: 16),
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
            onTap: () => _showUserSelector(context, ref),
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
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
            onTap: () => _showActionSelector(context, ref),
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
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
            onTap: () => _showModuleSelector(context, ref),
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
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
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'fechaInicio': null,
                'fechaFin': null,
              });
            },
          ),
          const SizedBox(height: 24),
          if (selectedBarId != null || selectedUsuarioId != null || selectedAction != null || selectedModule != null || isDateSelected)
            InkWell(
              onTap: () {
                ref.read(superAuditoriaFiltersProvider.notifier).state = {
                  'barId': null,
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
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.liquidPrimary.withOpacity(0.06) : const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.liquidPrimary.withOpacity(0.25) : Colors.white.withOpacity(0.04),
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
                  fontSize: 11.5,
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

  Widget _buildMainContent(
    AuditoriaState state,
    ThemeData theme,
    String currencyIso,
    String currencySymbol,
    String barTimezone,
    bool isTabletLandscape,
    Map<String, String> barMap,
  ) {
    Widget listWidget;

    if (state.isLoading) {
      listWidget = ListView.builder(
        padding: isTabletLandscape
            ? const EdgeInsets.fromLTRB(16, 8, 16, 16)
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
            ? const EdgeInsets.fromLTRB(16, 8, 16, 16)
            : const EdgeInsets.fromLTRB(16, 0, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: state.logs.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.logs.length) {
            final log = state.logs[index];
            final sucursalNombre = barMap[log.barId];
            return InkWell(
              onTap: () => showLogDetail(context, log, currencyIso, currencySymbol, barTimezone),
              borderRadius: BorderRadius.circular(16.0),
              child: AuditoriaLogCard(
                log: log,
                currencyIso: currencyIso,
                currencySymbol: currencySymbol,
                barTimezone: barTimezone,
                sucursalNombre: sucursalNombre,
                showBarLabel: true,
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

// Bar filter selector helper
void _showBarSelector(BuildContext context, WidgetRef ref) {
  final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

  Widget buildContent(BuildContext context, ScrollController? scrollController, bool isDialog) {
    return Consumer(
      builder: (context, ref, child) {
        final barsAsync = ref.watch(barsFutureProvider);
        final selectedId = ref.watch(superAuditoriaFiltersProvider)['barId'];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.liquidSurfaceContainerLow,
            borderRadius: isDialog
                ? BorderRadius.circular(24.0)
                : const BorderRadius.vertical(top: Radius.circular(28.0)),
            border: isDialog
                ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDialog)
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (!isDialog) const SizedBox(height: 20),
              Text(
                'Filtrar por Sucursal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: barsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                  ),
                  error: (err, st) => Center(
                    child: Text('Error al cargar sucursales: $err', style: TextStyle(color: AppTheme.colorDanger)),
                  ),
                  data: (bars) {
                    return ListView(
                      shrinkWrap: isDialog,
                      controller: scrollController,
                      children: [
                        _buildSelectorItem(
                          title: 'Todas las sucursales',
                          isSelected: selectedId == null,
                          onTap: () {
                            ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                              ...state,
                              'barId': null,
                            });
                            Navigator.pop(context);
                          },
                        ),
                        ...bars.map((bar) {
                          final id = bar['id']?.toString() ?? '';
                          final nombre = bar['nombre']?.toString() ?? '';
                          final zona = bar['zona']?.toString() ?? '';
                          final subtitle = zona.isNotEmpty ? 'Zona: $zona' : null;
                          return _buildSelectorItem(
                            title: nombre,
                            subtitle: subtitle,
                            isSelected: selectedId == id,
                            onTap: () {
                              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                                ...state,
                                'barId': id,
                              });
                              Navigator.pop(context);
                            },
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  if (isTabletLandscape) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
            child: buildContent(context, null, true),
          ),
        );
      },
    );
  } else {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return buildContent(context, scrollController, false);
          },
        );
      },
    );
  }
}

// User filter selector helper
void _showUserSelector(BuildContext context, WidgetRef ref) {
  final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

  Widget buildContent(BuildContext context, ScrollController? scrollController, bool isDialog) {
    return Consumer(
      builder: (context, ref, child) {
        final staffAsync = ref.watch(superStaffListProvider);
        final selectedId = ref.watch(superAuditoriaFiltersProvider)['usuarioId'];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.liquidSurfaceContainerLow,
            borderRadius: isDialog
                ? BorderRadius.circular(24.0)
                : const BorderRadius.vertical(top: Radius.circular(28.0)),
            border: isDialog
                ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDialog)
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (!isDialog) const SizedBox(height: 20),
              Text(
                'Filtrar por Usuario',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: staffAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                  ),
                  error: (err, st) => Center(
                    child: Text('Error al cargar usuarios: $err', style: TextStyle(color: AppTheme.colorDanger)),
                  ),
                  data: (users) {
                    return ListView(
                      shrinkWrap: isDialog,
                      controller: scrollController,
                      children: [
                        _buildSelectorItem(
                          title: 'Todos los usuarios',
                          isSelected: selectedId == null,
                          onTap: () {
                            ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                              ...state,
                              'usuarioId': null,
                            });
                            Navigator.pop(context);
                          },
                        ),
                        ...users.map((user) => _buildSelectorItem(
                          title: '${user.nombre} (${user.rolNombre.toLowerCase()})',
                          isSelected: selectedId == user.id,
                          onTap: () {
                            ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                              ...state,
                              'usuarioId': user.id,
                            });
                            Navigator.pop(context);
                          },
                        )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  if (isTabletLandscape) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
            child: buildContent(context, null, true),
          ),
        );
      },
    );
  } else {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return buildContent(context, scrollController, false);
          },
        );
      },
    );
  }
}

// Action selector helper
void _showActionSelector(BuildContext context, WidgetRef ref) {
  final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

  Widget buildContent(BuildContext context, ScrollController? scrollController, bool isDialog) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedAction = ref.watch(superAuditoriaFiltersProvider)['accion'];
        final actions = [
          'Crear',
          'Editar',
          'Eliminar',
          'APERTURA',
          'CIERRE',
          'REGISTRAR_MOVIMIENTO',
          'REGISTRAR_VENTA',
          'Inicio de Sesión',
          'Inicio de Sesión Fallido'
        ];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.liquidSurfaceContainerLow,
            borderRadius: isDialog
                ? BorderRadius.circular(24.0)
                : const BorderRadius.vertical(top: Radius.circular(28.0)),
            border: isDialog
                ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDialog)
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (!isDialog) const SizedBox(height: 20),
              Text(
                'Filtrar por Acción',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: isDialog,
                  controller: scrollController,
                  children: [
                    _buildSelectorItem(
                      title: 'Todas las acciones',
                      isSelected: selectedAction == null,
                      onTap: () {
                        ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                          ...state,
                          'accion': null,
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ...actions.map((action) => _buildSelectorItem(
                      title: AuditoriaFormatters.formatAction(action),
                      isSelected: selectedAction == action,
                      onTap: () {
                        ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                          ...state,
                          'accion': action,
                        });
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  if (isTabletLandscape) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
            child: buildContent(context, null, true),
          ),
        );
      },
    );
  } else {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return buildContent(context, scrollController, false);
          },
        );
      },
    );
  }
}

// Module selector helper
void _showModuleSelector(BuildContext context, WidgetRef ref) {
  final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

  Widget buildContent(BuildContext context, ScrollController? scrollController, bool isDialog) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedModule = ref.watch(superAuditoriaFiltersProvider)['modulo'];
        final modules = [
          'Sucursales',
          'Administradores',
          'Personal',
          'Ventas',
          'Cajas',
          'Productos',
          'Categorías',
          'Configuración',
          'Sesión'
        ];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.liquidSurfaceContainerLow,
            borderRadius: isDialog
                ? BorderRadius.circular(24.0)
                : const BorderRadius.vertical(top: Radius.circular(28.0)),
            border: isDialog
                ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDialog)
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (!isDialog) const SizedBox(height: 20),
              Text(
                'Filtrar por Módulo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: isDialog,
                  controller: scrollController,
                  children: [
                    _buildSelectorItem(
                      title: 'Todos los módulos',
                      isSelected: selectedModule == null,
                      onTap: () {
                        ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                          ...state,
                          'modulo': null,
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ...modules.map((mod) => _buildSelectorItem(
                      title: mod,
                      isSelected: selectedModule == mod,
                      onTap: () {
                        ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                          ...state,
                          'modulo': mod,
                        });
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  if (isTabletLandscape) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 500),
            child: buildContent(context, null, true),
          ),
        );
      },
    );
  } else {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return buildContent(context, scrollController, false);
          },
        );
      },
    );
  }
}

// Selector item widget
Widget _buildSelectorItem({
  required String title,
  String? subtitle,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 6.0),
    decoration: BoxDecoration(
      color: isSelected ? AppTheme.liquidSurfaceContainerHigh : Colors.transparent,
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(
        color: isSelected ? AppTheme.liquidPrimary : Colors.white.withOpacity(0.04),
        width: 1,
      ),
    ),
    child: ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 0.0),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: isSelected ? AppTheme.liquidPrimary.withOpacity(0.7) : Colors.white54,
                fontSize: 11,
              ),
            )
          : null,
      trailing: isSelected
          ? Icon(Icons.check_circle_outline, color: AppTheme.liquidPrimary, size: 18)
          : null,
      onTap: onTap,
    ),
  );
}

// Capsule filter list widget
class SuperAuditoriaFilterCapsules extends ConsumerWidget {
  const SuperAuditoriaFilterCapsules({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(superAuditoriaFiltersProvider);
    final staffAsync = ref.watch(superStaffListProvider);
    final barsAsync = ref.watch(barsFutureProvider);

    final Map<String, String> barMap = {};
    barsAsync.maybeWhen(
      data: (list) {
        for (final item in list) {
          if (item is Map) {
            final id = item['id']?.toString() ?? '';
            final nombre = item['nombre']?.toString() ?? '';
            if (id.isNotEmpty) barMap[id] = nombre;
          }
        }
      },
      orElse: () {},
    );

    final selectedBarId = filters['barId'];
    final selectedUsuarioId = filters['usuarioId'];
    final selectedAction = filters['accion'];
    final selectedModule = filters['modulo'];
    final start = filters['fechaInicio'];
    final end = filters['fechaFin'];
    final isDateSelected = start != null && end != null;

    String barLabel = 'Sucursal';
    if (selectedBarId != null) {
      barLabel = barMap[selectedBarId] ?? 'Sucursal Sel.';
    }

    String userLabel = 'Usuario';
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

    String dateLabel = 'Fechas';
    if (isDateSelected) {
      try {
        final startDt = DateTime.parse(start);
        final endDt = DateTime.parse(end);
        dateLabel = '${DateFormat('dd MMM').format(startDt)} - ${DateFormat('dd MMM').format(endDt)}';
      } catch (_) {}
    }

    final hasFilters = selectedBarId != null || selectedUsuarioId != null || selectedAction != null || selectedModule != null || isDateSelected;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildCapsuleItem(
            context,
            label: selectedBarId != null ? barLabel : 'Filtrar Sucursal',
            isActive: selectedBarId != null,
            onTap: () => _showBarSelector(context, ref),
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'barId': null,
              });
            },
          ),
          const SizedBox(width: 8),
          _buildCapsuleItem(
            context,
            label: selectedUsuarioId != null ? userLabel : 'Filtrar Usuario',
            isActive: selectedUsuarioId != null,
            onTap: () => _showUserSelector(context, ref),
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'usuarioId': null,
              });
            },
          ),
          const SizedBox(width: 8),
          _buildCapsuleItem(
            context,
            label: selectedAction != null ? AuditoriaFormatters.formatAction(selectedAction) : 'Filtrar Acción',
            isActive: selectedAction != null,
            onTap: () => _showActionSelector(context, ref),
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'accion': null,
              });
            },
          ),
          const SizedBox(width: 8),
          _buildCapsuleItem(
            context,
            label: selectedModule ?? 'Filtrar Módulo',
            isActive: selectedModule != null,
            onTap: () => _showModuleSelector(context, ref),
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'modulo': null,
              });
            },
          ),
          const SizedBox(width: 8),
          _buildCapsuleItem(
            context,
            label: isDateSelected ? dateLabel : 'Filtrar Fechas',
            isActive: isDateSelected,
            onTap: () {
              // Trigger select date range by creating a temporary state instance to get context
              // Or call the method statically if possible, or build a helper.
              // We can create a simple helper to trigger date range picker.
              _selectDateRangeStatic(context, ref);
            },
            onClear: () {
              ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
                ...state,
                'fechaInicio': null,
                'fechaFin': null,
              });
            },
          ),
          if (hasFilters) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                ref.read(superAuditoriaFiltersProvider.notifier).state = {
                  'barId': null,
                  'usuarioId': null,
                  'accion': null,
                  'modulo': null,
                  'fechaInicio': null,
                  'fechaFin': null,
                };
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.colorDanger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.colorDanger.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_off_outlined, color: AppTheme.colorDanger, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'LIMPIAR',
                      style: GoogleFonts.poppins(
                        color: AppTheme.colorDanger,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDateRangeStatic(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(superAuditoriaFiltersProvider);
    DateTimeRange? initialRange;
    if (filters['fechaInicio'] != null && filters['fechaFin'] != null) {
      initialRange = DateTimeRange(
        start: DateTime.parse(filters['fechaInicio']!),
        end: DateTime.parse(filters['fechaFin']!),
      );
    }

    final picked = await CustomDateRangePicker.show(context, initialRange);

    if (picked != null) {
      ref.read(superAuditoriaFiltersProvider.notifier).update((state) => {
        ...state,
        'fechaInicio': DateFormat('yyyy-MM-dd').format(picked.start),
        'fechaFin': DateFormat('yyyy-MM-dd').format(picked.end),
      });
    }
  }

  Widget _buildCapsuleItem(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.liquidPrimary.withOpacity(0.08) : const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppTheme.liquidPrimary.withOpacity(0.25) : Colors.white.withOpacity(0.03),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 12, color: AppTheme.colorDanger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
