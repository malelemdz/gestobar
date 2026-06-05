import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/utils/timezone_helper.dart';
import '../../caja/providers/caja_provider.dart';
import '../providers/bar_provider.dart';
import '../providers/auditoria_provider.dart';
import '../providers/staff_provider.dart';
import '../../auth/models/user_model.dart';
import '../data/models/auditoria_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auditoriaState = ref.watch(auditoriaListProvider);
    final filters = ref.watch(auditoriaFiltersProvider);
    final staffAsync = ref.watch(staffListProvider);
    final currencyIso = ref.watch(currencyIsoProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final barTimezone = ref.watch(barTimezoneProvider);
    return Scaffold(
      backgroundColor: AppTheme.liquidBg,
      body: Column(
        children: [
          // Capsule Filters Horizontal List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 0.0),
            child: Row(
              children: [
                _buildUserFilterCapsule(filters, staffAsync),
                const SizedBox(width: 8),
                _buildActionFilterCapsule(filters),
                const SizedBox(width: 8),
                _buildModuleFilterCapsule(filters),
                const SizedBox(width: 8),
                _buildDateFilterCapsule(filters),
              ],
            ),
          ),
          // Log List
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.liquidPrimary,
              backgroundColor: const Color(0xFF1E2024),
              onRefresh: () async {
                await ref.read(auditoriaListProvider.notifier).loadInitial(silent: true);
              },
              child: _buildMainContent(auditoriaState, theme, currencyIso, currencySymbol, barTimezone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(AuditoriaState state, ThemeData theme, String currencyIso, String currencySymbol, String barTimezone) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 24.0),
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
    }

    if (state.errorMessage != null && state.logs.isEmpty) {
      return SingleChildScrollView(
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
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.logs.isEmpty) {
      return SingleChildScrollView(
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
                  style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 24.0),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: state.logs.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < state.logs.length) {
          final log = state.logs[index];
          return InkWell(
            onTap: () => _showLogDetail(context, log, currencyIso, currencySymbol, barTimezone),
            borderRadius: BorderRadius.circular(16.0),
            child: _buildLogCard(log, theme, currencyIso, currencySymbol, barTimezone),
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

  Widget _buildLogCard(AuditoriaModel log, ThemeData theme, String currencyIso, String currencySymbol, String barTimezone) {
    final format = DateFormat('dd MMM, HH:mm:ss');
    final localFecha = TimezoneHelper.convertToBarTime(log.fecha, barTimezone);
    final dateStr = format.format(localFecha);

    Color actionColor = AppTheme.liquidPrimary;
    IconData actionIcon = Icons.info_outline;

    if (log.accion == 'Crear') {
      actionColor = AppTheme.colorSuccess;
      actionIcon = Icons.add_circle_outline;
    } else if (log.accion == 'Editar') {
      actionColor = Colors.orangeAccent;
      actionIcon = Icons.edit_outlined;
    } else if (log.accion == 'Eliminar') {
      actionColor = AppTheme.colorWarning;
      actionIcon = Icons.delete_outline;
    } else if (log.accion == 'Inicio de Sesión') {
      actionColor = Colors.cyanAccent;
      actionIcon = Icons.vpn_key_outlined;
    } else if (log.accion == 'Inicio de Sesión Fallido') {
      actionColor = AppTheme.colorDanger;
      actionIcon = Icons.gpp_bad_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.liquidSurfaceContainerLow,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(actionIcon, color: actionColor, size: 20),
              const SizedBox(width: 8),
              Text(
                _formatAction(log.accion),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: actionColor,
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatMessageWithCurrency(log.detalles?['mensaje'], currencyIso, currencySymbol),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.5, color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${log.usuarioNombre ?? "Usuario"} (${log.rolNombre.toLowerCase()})',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.folder_open, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                _formatModulo(log.modulo),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          if (log.dispositivo != null || log.ipAddress != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (log.dispositivo != null) ...[
                  const Icon(Icons.devices, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      log.dispositivo!,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white38),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (log.ipAddress != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.network_wifi, size: 14, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    _formatIpAddress(log.ipAddress),
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ],
            ),
          ]
        ],
      ),
    );
  }

  // --- FILTER CAPSULES BUILDERS ---

  Widget _buildUserFilterCapsule(Map<String, String?> filters, AsyncValue<List<UserModel>> staffAsync) {
    final selectedUsuarioId = filters['usuarioId'];
    final isSelected = selectedUsuarioId != null;

    String label = 'Usuario';
    if (isSelected) {
      label = staffAsync.maybeWhen(
        data: (users) {
          for (final u in users) {
            if (u.id == selectedUsuarioId) return u.nombre;
          }
          return 'Usuario Sel.';
        },
        orElse: () => 'Usuario Sel.',
      );
    }

    return _buildFilterChip(
      label: label,
      isSelected: isSelected,
      onTap: () => _showUserSelector(context),
      onClear: () {
        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
          ...state,
          'usuarioId': null,
        });
      },
    );
  }

  Widget _buildActionFilterCapsule(Map<String, String?> filters) {
    final selectedAction = filters['accion'];
    final isSelected = selectedAction != null;

    return _buildFilterChip(
      label: isSelected ? _formatAction(selectedAction) : 'Acción',
      isSelected: isSelected,
      onTap: () => _showActionSelector(context),
      onClear: () {
        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
          ...state,
          'accion': null,
        });
      },
    );
  }

  Widget _buildModuleFilterCapsule(Map<String, String?> filters) {
    final selectedModule = filters['modulo'];
    final isSelected = selectedModule != null;

    return _buildFilterChip(
      label: selectedModule ?? 'Módulo',
      isSelected: isSelected,
      onTap: () => _showModuleSelector(context),
      onClear: () {
        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
          ...state,
          'modulo': null,
        });
      },
    );
  }

  Widget _buildDateFilterCapsule(Map<String, String?> filters) {
    final start = filters['fechaInicio'];
    final end = filters['fechaFin'];
    final isSelected = start != null && end != null;

    String label = 'Fechas';
    if (isSelected) {
      try {
        final startDt = DateTime.parse(start);
        final endDt = DateTime.parse(end);
        final format = DateFormat('dd MMM');
        label = '${format.format(startDt)} - ${format.format(endDt)}';
      } catch (_) {}
    }

    return _buildFilterChip(
      label: label,
      isSelected: isSelected,
      onTap: () => _selectDateRange(context),
      onClear: () {
        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
          ...state,
          'fechaInicio': null,
          'fechaFin': null,
        });
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            if (isSelected) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 14,
                color: Colors.white.withOpacity(0.4),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // --- FILTER SELECTOR SHEETS ---

  void _showUserSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.liquidSurfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final staffAsync = ref.watch(staffListProvider);
                final selectedId = ref.watch(auditoriaFiltersProvider)['usuarioId'];
                return Container(
                  padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 20),
                      Text(
                        'Filtrar por Usuario',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: staffAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                          ),
                          error: (err, st) => Center(
                            child: Text('Error al cargar usuarios: $err', style: TextStyle(color: AppTheme.colorDanger)),
                          ),
                          data: (users) {
                            return ListView(
                              controller: scrollController,
                              children: [
                                _buildSelectorItem(
                                  title: 'Todos los usuarios',
                                  isSelected: selectedId == null,
                                  onTap: () {
                                    ref.read(auditoriaFiltersProvider.notifier).update((state) => {
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
                                    ref.read(auditoriaFiltersProvider.notifier).update((state) => {
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
          },
        );
      },
    );
  }

  void _showActionSelector(BuildContext context) {
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
    final selectedAction = ref.read(auditoriaFiltersProvider)['accion'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.liquidSurfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),
                  Text(
                    'Filtrar por Acción',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildSelectorItem(
                          title: 'Todas las acciones',
                          isSelected: selectedAction == null,
                          onTap: () {
                            ref.read(auditoriaFiltersProvider.notifier).update((state) => {
                              ...state,
                              'accion': null,
                            });
                            Navigator.pop(context);
                          },
                        ),
                        ...actions.map((action) => _buildSelectorItem(
                          title: _formatAction(action),
                          isSelected: selectedAction == action,
                          onTap: () {
                            ref.read(auditoriaFiltersProvider.notifier).update((state) => {
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
          },
        );
      },
    );
  }

  void _showModuleSelector(BuildContext context) {
    final modules = [
      'Ventas',
      'Cajas',
      'Productos',
      'Categorías',
      'Usuarios',
      'Roles',
      'Tarifas',
      'Configuración de Local',
      'Sesión'
    ];
    final selectedModule = ref.read(auditoriaFiltersProvider)['modulo'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.liquidSurfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 20),
                  Text(
                    'Filtrar por Módulo',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildSelectorItem(
                          title: 'Todos los módulos',
                          isSelected: selectedModule == null,
                          onTap: () {
                            ref.read(auditoriaFiltersProvider.notifier).update((state) => {
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
                            ref.read(auditoriaFiltersProvider.notifier).update((state) => {
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
          },
        );
      },
    );
  }

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
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
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

  Future<void> _selectDateRange(BuildContext context) async {
    final filters = ref.read(auditoriaFiltersProvider);
    DateTimeRange? initialRange;
    if (filters['fechaInicio'] != null && filters['fechaFin'] != null) {
      initialRange = DateTimeRange(
        start: DateTime.parse(filters['fechaInicio']!),
        end: DateTime.parse(filters['fechaFin']!),
      );
    }

    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: AppTheme.liquidSurfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return _CustomDateRangePicker(initialRange: initialRange);
      },
    );

    if (picked != null) {
      ref.read(auditoriaFiltersProvider.notifier).update((state) => {
        ...state,
        'fechaInicio': DateFormat('yyyy-MM-dd').format(picked.start),
        'fechaFin': DateFormat('yyyy-MM-dd').format(picked.end),
      });
    }
  }

  // --- LOG ENTRY DETAIL VIEWER ---

  void _showLogDetail(BuildContext context, AuditoriaModel log, String currencyIso, String currencySymbol, String barTimezone) {
    final format = DateFormat('dd MMMM yyyy, HH:mm:ss');
    final localFecha = TimezoneHelper.convertToBarTime(log.fecha, barTimezone);
    final dateStr = format.format(localFecha);

    Color actionColor = AppTheme.liquidPrimary;
    IconData actionIcon = Icons.info_outline;

    if (log.accion == 'Crear') {
      actionColor = AppTheme.colorSuccess;
      actionIcon = Icons.add_circle_outline;
    } else if (log.accion == 'Editar') {
      actionColor = Colors.orangeAccent;
      actionIcon = Icons.edit_outlined;
    } else if (log.accion == 'Eliminar') {
      actionColor = AppTheme.colorWarning;
      actionIcon = Icons.delete_outline;
    } else if (log.accion == 'Inicio de Sesión') {
      actionColor = Colors.cyanAccent;
      actionIcon = Icons.vpn_key_outlined;
    } else if (log.accion == 'Inicio de Sesión Fallido') {
      actionColor = AppTheme.colorDanger;
      actionIcon = Icons.gpp_bad_outlined;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.liquidSurfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Icon(actionIcon, color: actionColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatMessageWithCurrency(log.detalles?['mensaje'], currencyIso, currencySymbol),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white70, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5, color: Colors.white10),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(Icons.folder_open_outlined, 'Módulo', _formatModulo(log.modulo)),
                          _buildDetailRow(Icons.person_outline, 'Usuario', '${log.usuarioNombre ?? "Desconocido"} (${log.rolNombre.toLowerCase()})'),
                          _buildDetailRow(Icons.calendar_today_outlined, 'Fecha ($barTimezone)', dateStr),
                          if (log.ipAddress != null)
                            _buildDetailRow(Icons.network_wifi_outlined, 'Dirección IP', _formatIpAddress(log.ipAddress)),
                          if (log.dispositivo != null)
                            _buildDetailRow(Icons.devices_outlined, 'Dispositivo/User Agent', log.dispositivo!),
                          
                          const SizedBox(height: 16),

                          _buildLogMetadataDetail(log, currencyIso, currencySymbol),
                          
                          // Render detailed changes if 'cambios' exists
                          if (log.detalles != null && log.detalles!['cambios'] != null) ...[
                            Text(
                              'CAMBIOS REALIZADOS',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppTheme.liquidPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildChangesList(log.detalles!['cambios'], currencyIso, currencySymbol),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogMetadataDetail(AuditoriaModel log, String currencyIso, String currencySymbol) {
    if (log.detalles == null) return const SizedBox.shrink();
    final det = log.detalles!;
    
    final action = log.accion;
    if (action != 'REGISTRAR_VENTA' && 
        action != 'APERTURA' && 
        action != 'CIERRE' && 
        action != 'REGISTRAR_MOVIMIENTO') {
      return const SizedBox.shrink();
    }

    String title = '';
    List<Widget> items = [];

    if (action == 'REGISTRAR_VENTA') {
      title = 'DETALLES DE LA VENTA';
      final totalVal = double.tryParse(det['total']?.toString() ?? '0') ?? 0.0;
      final metodo = det['metodo_pago']?.toString() ?? 'Desconocido';
      final itemsCount = det['cantidad_items']?.toString() ?? '0';
      final ventaId = det['venta_id']?.toString() ?? '';
      
      items = [
        _buildMetadataItem('ID Venta', ventaId.length > 8 ? '#${ventaId.substring(0, 8)}' : '#$ventaId', icon: Icons.receipt_long_outlined),
        _buildMetadataItem('Total Procesado', '$currencySymbol${CurrencyHelper.formatAmount(totalVal, currencyIso)}', isHighlight: true, highlightColor: AppTheme.colorSuccess, icon: Icons.monetization_on_outlined),
        _buildMetadataItem('Método de Pago', metodo, icon: Icons.payment_outlined),
        _buildMetadataItem('Cantidad de Items', itemsCount, icon: Icons.shopping_bag_outlined),
      ];
    } else if (action == 'APERTURA') {
      title = 'APERTURA DE CAJA';
      final montoInicialVal = double.tryParse(det['monto_inicial']?.toString() ?? '0') ?? 0.0;
      final cajaId = det['caja_id']?.toString() ?? '';

      items = [
        _buildMetadataItem('ID Caja', cajaId.length > 8 ? '#${cajaId.substring(0, 8)}' : '#$cajaId', icon: Icons.folder_open_outlined),
        _buildMetadataItem('Monto Inicial', '$currencySymbol${CurrencyHelper.formatAmount(montoInicialVal, currencyIso)}', isHighlight: true, highlightColor: AppTheme.liquidPrimary, icon: Icons.account_balance_wallet_outlined),
      ];
    } else if (action == 'CIERRE') {
      title = 'RESUMEN DE CIERRE DE CAJA';
      final montoInicialVal = double.tryParse(det['monto_inicial']?.toString() ?? '0') ?? 0.0;
      final montoFinalVal = double.tryParse(det['monto_final']?.toString() ?? '0') ?? 0.0;
      final ventasVal = double.tryParse(det['ventas_totales']?.toString() ?? '0') ?? 0.0;
      final comisionesVal = double.tryParse(det['comisiones_pagadas']?.toString() ?? '0') ?? 0.0;
      final ingresosVal = double.tryParse(det['ingresos_manuales']?.toString() ?? '0') ?? 0.0;
      final egresosVal = double.tryParse(det['egresos_manuales']?.toString() ?? '0') ?? 0.0;
      final esperadoVal = double.tryParse(det['balance_esperado']?.toString() ?? '0') ?? 0.0;
      final cajaId = det['caja_id']?.toString() ?? '';

      items = [
        _buildMetadataItem('ID Caja', cajaId.length > 8 ? '#${cajaId.substring(0, 8)}' : '#$cajaId', icon: Icons.folder_open_outlined),
        _buildMetadataItem('Monto Inicial', '$currencySymbol${CurrencyHelper.formatAmount(montoInicialVal, currencyIso)}', icon: Icons.account_balance_wallet_outlined),
        _buildMetadataItem('Ventas Totales (+)', '$currencySymbol${CurrencyHelper.formatAmount(ventasVal, currencyIso)}', highlightColor: AppTheme.colorSuccess, icon: Icons.add_circle_outline),
        _buildMetadataItem('Ingresos Manuales (+)', '$currencySymbol${CurrencyHelper.formatAmount(ingresosVal, currencyIso)}', icon: Icons.arrow_upward_outlined),
        _buildMetadataItem('Egresos Manuales (-)', '$currencySymbol${CurrencyHelper.formatAmount(egresosVal, currencyIso)}', icon: Icons.arrow_downward_outlined),
        _buildMetadataItem('Comisiones Pagadas (-)', '$currencySymbol${CurrencyHelper.formatAmount(comisionesVal, currencyIso)}', highlightColor: AppTheme.colorDanger, icon: Icons.percent_outlined),
        _buildMetadataItem('Balance Esperado', '$currencySymbol${CurrencyHelper.formatAmount(esperadoVal, currencyIso)}', icon: Icons.calculate_outlined),
        _buildMetadataItem('Monto Final Registrado', '$currencySymbol${CurrencyHelper.formatAmount(montoFinalVal, currencyIso)}', isHighlight: true, highlightColor: AppTheme.liquidPrimary, icon: Icons.price_check_outlined),
      ];
    } else if (action == 'REGISTRAR_MOVIMIENTO') {
      title = 'DETALLES DE MOVIMIENTO';
      final tipo = det['tipo']?.toString() ?? '';
      final montoVal = double.tryParse(det['monto']?.toString() ?? '0') ?? 0.0;
      final concepto = det['concepto']?.toString() ?? 'Sin concepto';
      final metodo = det['metodo_pago']?.toString() ?? 'Efectivo';
      final movId = det['movimiento_id']?.toString() ?? '';

      final isIngreso = tipo.toUpperCase() == 'INGRESO';
      final tipoColor = isIngreso ? AppTheme.colorSuccess : AppTheme.colorDanger;
      final tipoIcon = isIngreso ? Icons.arrow_upward_outlined : Icons.arrow_downward_outlined;

      items = [
        _buildMetadataItem('ID Movimiento', movId.length > 8 ? '#${movId.substring(0, 8)}' : '#$movId', icon: Icons.receipt_outlined),
        _buildMetadataItem('Tipo de Movimiento', isIngreso ? 'Ingreso' : 'Egreso', highlightColor: tipoColor, icon: tipoIcon),
        _buildMetadataItem('Monto', '$currencySymbol${CurrencyHelper.formatAmount(montoVal, currencyIso)}', isHighlight: true, highlightColor: tipoColor, icon: Icons.monetization_on_outlined),
        _buildMetadataItem('Concepto', concepto, icon: Icons.label_outline),
        _buildMetadataItem('Método de Pago', metodo, icon: Icons.payment_outlined),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: AppTheme.liquidPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppTheme.liquidSurfaceContainerHigh,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            children: items,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMetadataItem(String label, String value, {bool isHighlight = false, Color? highlightColor, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: (highlightColor ?? Colors.white70).withOpacity(0.7)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? (highlightColor ?? AppTheme.liquidPrimary) : (highlightColor ?? Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.liquidOnSurfaceVariant.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: AppTheme.liquidOnSurfaceVariant.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesList(Map<String, dynamic> cambios, String currencyIso, String currencySymbol) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.liquidSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        children: cambios.entries.map((entry) {
          final field = entry.key;
          var de = entry.value['de']?.toString() ?? 'vacío';
          var a = entry.value['a']?.toString() ?? 'vacío';

          final isCurrencyField = field == 'precio' ||
              field == 'comision' ||
              field == 'monto' ||
              field == 'diferencia' ||
              field == 'precio_unitario' ||
              field == 'monto_apertura' ||
              field == 'monto_cierre' ||
              field == 'monto_real';

          if (isCurrencyField) {
            final deNum = double.tryParse(de);
            if (deNum != null) {
              de = '$currencySymbol${CurrencyHelper.formatAmount(deNum, currencyIso)}';
            }
            final aNum = double.tryParse(a);
            if (aNum != null) {
              a = '$currencySymbol${CurrencyHelper.formatAmount(aNum, currencyIso)}';
            }
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFieldKey(field),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppTheme.colorDanger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          de,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.colorDanger,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Icon(Icons.arrow_forward, size: 16, color: Colors.white24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: AppTheme.colorSuccess.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          a,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.colorSuccess,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- TEXT & DATA FORMATTING HELPERS ---

  String _formatMessageWithCurrency(String? message, String currencyIso, String currencySymbol) {
    if (message == null) return 'Acción registrada';
    final regExp = RegExp(r'\$([0-9]+(?:\.[0-9]+)?)');
    
    return message.replaceAllMapped(regExp, (match) {
      final valStr = match.group(1);
      if (valStr == null) return match.group(0)!;
      final val = double.tryParse(valStr);
      if (val == null) return match.group(0)!;
      return '$currencySymbol${CurrencyHelper.formatAmount(val, currencyIso)}';
    });
  }

  String _formatAction(String action) {
    if (action.isEmpty) return '';
    final knownTranslations = {
      'APERTURA': 'Apertura de caja',
      'CIERRE': 'Cierre de caja',
      'REGISTRAR_MOVIMIENTO': 'Registrar movimiento',
      'REGISTRAR_VENTA': 'Registrar venta',
      'Inicio de Sesión': 'Inicio de sesión',
      'Inicio de Sesión Fallido': 'Inicio de sesión fallido',
      'Crear': 'Crear',
      'Editar': 'Editar',
      'Eliminar': 'Eliminar',
    };

    if (knownTranslations.containsKey(action)) {
      return knownTranslations[action]!;
    }

    String formatted = action.replaceAll('_', ' ').trim();
    if (formatted.isEmpty) return '';
    formatted = formatted.toLowerCase();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  String _formatModulo(String modulo) {
    if (modulo.isEmpty) return '';
    String formatted = modulo.replaceAll('_', ' ').trim();
    if (formatted.isEmpty) return '';
    formatted = formatted.toLowerCase();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  String _formatIpAddress(String? ip) {
    if (ip == null) return 'Desconocido';
    if (ip.startsWith('::ffff:')) {
      return ip.substring(7);
    }
    if (ip == '::1') {
      return '127.0.0.1 (Localhost)';
    }
    return ip;
  }

  String _formatFieldKey(String key) {
    if (key.isEmpty) return '';
    final translations = {
      'nombre': 'Nombre',
      'username': 'Nombre de usuario',
      'estado': 'Estado',
      'celular': 'Celular',
      'identificacion': 'Identificación',
      'nacionalidad': 'Nacionalidad',
      'direccion': 'Dirección',
      'genero': 'Género',
      'foto_url': 'Foto',
      'rol_id': 'Rol',
      'rol_nombre': 'Nombre de rol',
      'precio': 'Precio',
      'descripcion': 'Descripción',
      'disponible': 'Disponible',
      'orden': 'Orden',
      'bar_id': 'Bar',
      'bar_slug': 'Slug del bar',
      'monto_apertura': 'Monto de apertura',
      'monto_cierre': 'Monto de cierre',
      'monto_real': 'Monto real',
      'diferencia': 'Diferencia',
      'comision': 'Comisión',
      'tarifa_id': 'Tarifa',
    };
    if (translations.containsKey(key)) {
      return translations[key]!;
    }
    String formatted = key.replaceAll('_', ' ').trim();
    if (formatted.isEmpty) return '';
    formatted = formatted.toLowerCase();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}

class _CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  const _CustomDateRangePicker({this.initialRange});

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  late DateTime _focusedMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialRange?.start;
    _endDate = widget.initialRange?.end;
    _focusedMonth = _startDate ?? DateTime.now();
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
  }

  int _daysInMonth(DateTime date) {
    var firstDayOfNextMonth = DateTime(date.year, date.month + 1, 1);
    var lastDayOfThisMonth = firstDayOfNextMonth.subtract(const Duration(days: 1));
    return lastDayOfThisMonth.day;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<DateTime> _generateCalendarDays() {
    final days = <DateTime>[];
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    
    final pad = firstDay.weekday - 1;
    
    final prevMonth = DateTime(year, month - 1, 1);
    final daysInPrevMonth = _daysInMonth(prevMonth);
    for (int i = pad - 1; i >= 0; i--) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i));
    }
    
    final daysInCurrentMonth = _daysInMonth(firstDay);
    for (int i = 1; i <= daysInCurrentMonth; i++) {
      days.add(DateTime(year, month, i));
    }
    
    final totalCells = 42;
    final nextMonth = DateTime(year, month + 1, 1);
    final remaining = totalCells - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(nextMonth.year, nextMonth.month, i));
    }
    
    return days;
  }

  void _onDayTapped(DateTime day) {
    final normDay = _normalizeDate(day);
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = normDay;
        _endDate = null;
      } else {
        if (normDay.isBefore(_startDate!)) {
          _startDate = normDay;
          _endDate = null;
        } else {
          _endDate = normDay;
        }
      }
    });
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normStart = _startDate != null ? _normalizeDate(_startDate!) : null;
    final normEnd = _endDate != null ? _normalizeDate(_endDate!) : null;
    
    final df = DateFormat('dd MMM, yyyy', 'es');
    final startText = _startDate != null ? df.format(_startDate!) : 'Fecha Inicio';
    final endText = _endDate != null ? df.format(_endDate!) : 'Fecha Fin';

    final monthName = DateFormat('MMMM yyyy', 'es').format(_focusedMonth);
    final formattedMonth = monthName[0].toUpperCase() + monthName.substring(1);

    final weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final days = _generateCalendarDays();

    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
      decoration: BoxDecoration(
        color: AppTheme.liquidSurfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicator bar
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
            const SizedBox(height: 16),
            
            // Header
            Text(
              'Seleccionar Rango de Fechas',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Visual range boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: _startDate != null ? AppTheme.liquidPrimary.withOpacity(0.06) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _startDate != null ? AppTheme.liquidPrimary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DESDE',
                          style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          startText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold, 
                            color: _startDate != null ? Colors.white : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 14),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: _endDate != null ? AppTheme.liquidPrimary.withOpacity(0.06) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _endDate != null ? AppTheme.liquidPrimary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HASTA',
                          style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          endText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, 
                            fontWeight: FontWeight.bold, 
                            color: _endDate != null ? Colors.white : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Quick options
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildQuickDateChip('Hoy', () {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, now.day);
                    final end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
                    setState(() {
                      _startDate = start;
                      _endDate = end;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildQuickDateChip('Ayer', () {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, now.day - 1);
                    final end = start.add(const Duration(hours: 23, minutes: 59, seconds: 59));
                    setState(() {
                      _startDate = start;
                      _endDate = end;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildQuickDateChip('Últimos 7 días', () {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, now.day - 6);
                    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    setState(() {
                      _startDate = start;
                      _endDate = end;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildQuickDateChip('Este mes', () {
                    final now = DateTime.now();
                    final start = DateTime(now.year, now.month, 1);
                    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                    setState(() {
                      _startDate = start;
                      _endDate = end;
                    });
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5, color: Colors.white10),
            const SizedBox(height: 12),
            
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                    });
                  },
                ),
                Text(
                  formattedMonth,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Weekdays
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            
            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final d = days[index];
                final normD = _normalizeDate(d);
                
                final isSelectedStart = normStart != null && normD.isAtSameMomentAs(normStart);
                final isSelectedEnd = normEnd != null && normD.isAtSameMomentAs(normEnd);
                final isInRange = normStart != null && normEnd != null && normD.isAfter(normStart) && normD.isBefore(normEnd);
                final isToday = normD.isAtSameMomentAs(_normalizeDate(DateTime.now()));
                final isCurrentMonth = normD.month == _focusedMonth.month;

                BoxDecoration? rangeDecoration;
                if (isInRange) {
                  rangeDecoration = BoxDecoration(
                    color: AppTheme.liquidPrimary.withOpacity(0.12),
                  );
                } else if (isSelectedStart && normEnd != null) {
                  rangeDecoration = BoxDecoration(
                    color: AppTheme.liquidPrimary.withOpacity(0.12),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                  );
                } else if (isSelectedEnd) {
                  rangeDecoration = BoxDecoration(
                    color: AppTheme.liquidPrimary.withOpacity(0.12),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                  );
                }

                return GestureDetector(
                  onTap: () => _onDayTapped(d),
                  child: Container(
                    decoration: rangeDecoration,
                    child: Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isSelectedStart || isSelectedEnd)
                              ? AppTheme.liquidPrimary
                              : Colors.transparent,
                          border: isToday && !(isSelectedStart || isSelectedEnd)
                              ? Border.all(color: AppTheme.liquidPrimary.withOpacity(0.4), width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${normD.day}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: (isSelectedStart || isSelectedEnd) ? FontWeight.bold : FontWeight.w600,
                              color: (isSelectedStart || isSelectedEnd)
                                  ? Colors.black
                                  : isCurrentMonth
                                      ? Colors.white
                                      : Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Footer buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _startDate != null ? AppTheme.liquidPrimary : Colors.white.withOpacity(0.04),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white.withOpacity(0.04),
                      disabledForegroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: _startDate != null
                        ? () {
                            final end = _endDate ?? _startDate!;
                            Navigator.pop(
                              context,
                              DateTimeRange(
                                start: DateTime(_startDate!.year, _startDate!.month, _startDate!.day),
                                end: DateTime(end.year, end.month, end.day, 23, 59, 59),
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      'Aceptar',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _startDate != null ? Colors.black : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
