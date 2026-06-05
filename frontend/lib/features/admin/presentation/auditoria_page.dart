import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
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
              child: _buildMainContent(auditoriaState, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(AuditoriaState state, ThemeData theme) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
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
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 24.0),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemCount: state.logs.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < state.logs.length) {
          final log = state.logs[index];
          return InkWell(
            onTap: () => _showLogDetail(context, log),
            borderRadius: BorderRadius.circular(16.0),
            child: _buildLogCard(log, theme),
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

  Widget _buildLogCard(AuditoriaModel log, ThemeData theme) {
    final format = DateFormat('dd MMM, HH:mm:ss');
    final dateStr = format.format(log.fecha);

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
            log.detalles?['mensaje'] ?? 'Acción registrada',
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
                log.modulo,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final staffAsync = ref.watch(staffListProvider);
            final selectedId = ref.watch(auditoriaFiltersProvider)['usuarioId'];
            return Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtrar por Usuario',
                    style: GoogleFonts.plusJakartaSans(
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
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              title: Text('Todos los usuarios', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                              selected: selectedId == null,
                              selectedTileColor: Colors.white.withOpacity(0.05),
                              onTap: () {
                                ref.read(auditoriaFiltersProvider.notifier).update((state) => {
                                  ...state,
                                  'usuarioId': null,
                                });
                                Navigator.pop(context);
                              },
                            ),
                            ...users.map((user) => ListTile(
                              title: Text(user.nombre, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                              subtitle: Text(user.rolNombre.toLowerCase(), style: GoogleFonts.plusJakartaSans(color: Colors.white54)),
                              selected: selectedId == user.id,
                              selectedTileColor: Colors.white.withOpacity(0.05),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por Acción',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: Text('Todas las acciones', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                      selected: selectedAction == null,
                      selectedTileColor: Colors.white.withOpacity(0.05),
                      onTap: () {
                        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
                          ...state,
                          'accion': null,
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ...actions.map((action) => ListTile(
                      title: Text(_formatAction(action), style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                      selected: selectedAction == action,
                      selectedTileColor: Colors.white.withOpacity(0.05),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por Módulo',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: Text('Todos los módulos', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                      selected: selectedModule == null,
                      selectedTileColor: Colors.white.withOpacity(0.05),
                      onTap: () {
                        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
                          ...state,
                          'modulo': null,
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ...modules.map((mod) => ListTile(
                      title: Text(mod, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                      selected: selectedModule == mod,
                      selectedTileColor: Colors.white.withOpacity(0.05),
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

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.liquidPrimary,
              onPrimary: Colors.black,
              surface: AppTheme.liquidSurfaceContainerLow,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
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

  void _showLogDetail(BuildContext context, AuditoriaModel log) {
    final format = DateFormat('dd MMMM yyyy, HH:mm:ss');
    final dateStr = format.format(log.fecha);

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
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
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
                  Row(
                    children: [
                      Icon(actionIcon, color: actionColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _formatAction(log.accion),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: actionColor,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.liquidSurfaceContainerHigh,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          log.modulo,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: AppTheme.liquidOnSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    log.detalles?['mensaje'] ?? 'Detalles de la acción',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildDetailRow(Icons.person_outline, 'Usuario', '${log.usuarioNombre ?? "Desconocido"} (${log.rolNombre.toLowerCase()})'),
                        _buildDetailRow(Icons.calendar_today_outlined, 'Fecha', dateStr),
                        if (log.ipAddress != null)
                          _buildDetailRow(Icons.network_wifi_outlined, 'Dirección IP', _formatIpAddress(log.ipAddress)),
                        if (log.dispositivo != null)
                          _buildDetailRow(Icons.devices_outlined, 'Dispositivo/User Agent', log.dispositivo!),
                        
                        const SizedBox(height: 16),
                        
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
                          _buildChangesList(log.detalles!['cambios']),
                        ],
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

  Widget _buildChangesList(Map<String, dynamic> cambios) {
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
          final de = entry.value['de']?.toString() ?? 'vacío';
          final a = entry.value['a']?.toString() ?? 'vacío';
          
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
