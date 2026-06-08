import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/auditoria_provider.dart';
import '../../providers/staff_provider.dart';
import '../utils/auditoria_formatters.dart';

void showUserSelector(BuildContext context, WidgetRef ref) {
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

void showActionSelector(BuildContext context, WidgetRef ref) {
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
              final selectedAction = ref.watch(auditoriaFiltersProvider)['accion'];
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
                            title: AuditoriaFormatters.formatAction(action),
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
            }
          );
        },
      );
    },
  );
}

void showModuleSelector(BuildContext context, WidgetRef ref) {
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
              final selectedModule = ref.watch(auditoriaFiltersProvider)['modulo'];
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
            }
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
