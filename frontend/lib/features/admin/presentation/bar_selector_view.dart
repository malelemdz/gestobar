import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/premium_fab.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../data/models/bar_model.dart';
import 'dialogs/bar_form_dialog.dart';
import 'dialogs/bar_status_confirmation_bottom_sheet.dart';
import '../../../core/widgets/responsive_modal.dart';

// Provider global para consultar las sucursales del sistema
final barsFutureProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.bars);
  return response.data as List<dynamic>;
});

class BarSelectorView extends ConsumerStatefulWidget {
  const BarSelectorView({super.key});

  @override
  ConsumerState<BarSelectorView> createState() => _BarSelectorViewState();
}

class _BarSelectorViewState extends ConsumerState<BarSelectorView> {
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'

  Future<void> _toggleBarEstado(BarModel bar, bool newEstado) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/bars/${bar.id}', data: {
        'estado': newEstado,
      });
      ref.refresh(barsFutureProvider);
      if (mounted) {
        CustomToast.show(
          context,
          message: newEstado
              ? 'Sucursal "${bar.nombre}" habilitada con éxito.'
              : 'Sucursal "${bar.nombre}" deshabilitada con éxito.',
          type: newEstado ? ToastType.success : ToastType.info,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error al cambiar el estado: $e',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barsAsync = ref.watch(barsFutureProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: PremiumFAB(
        label: 'Registrar Sucursal',
        icon: Icons.add,
        onPressed: () {
          showResponsiveDialog(
            context: context,
            maxWidth: 550,
            child: BarFormDialog(
              onSaved: () {
                ref.refresh(barsFutureProvider);
              },
            ),
          );
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background,
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Buscador full width al estilo de POS (Buscador arriba, altura 48, fondo 0xFF1E2024, bordes 12)
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2024),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00F0FF), size: 20),
                      hintText: 'Buscar sucursal',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(height: 12.0),

                // Filtros de Estado distribuidos en todo el ancho abajo del buscador
                Row(
                  children: [
                    _buildFilterChip('Todos', 'ALL', isFirst: true),
                    _buildFilterChip('Activos', 'ACTIVE'),
                    _buildFilterChip('Inactivos', 'INACTIVE', isLast: true),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Grilla de Bares
                Expanded(
                  child: barsAsync.when(
                    data: (rawBars) {
                      // Mapear y filtrar localmente
                      var bars = rawBars.map((b) => BarModel.fromJson(b as Map<String, dynamic>)).toList();

                      // Aplicar Búsqueda
                      if (_searchQuery.isNotEmpty) {
                        bars = bars.where((b) {
                          return b.nombre.toLowerCase().contains(_searchQuery) ||
                              b.slug.toLowerCase().contains(_searchQuery) ||
                              (b.ciudad != null && b.ciudad!.toLowerCase().contains(_searchQuery));
                        }).toList();
                      }

                      // Aplicar Filtro de Estado
                      if (_statusFilter == 'ACTIVE') {
                        bars = bars.where((b) => b.estado == true).toList();
                      } else if (_statusFilter == 'INACTIVE') {
                        bars = bars.where((b) => b.estado == false).toList();
                      }

                      if (bars.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront,
                                size: 64.0,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                'No se encontraron sucursales.',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400.0,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 4.0,
                        ),
                        itemCount: bars.length,
                        itemBuilder: (context, index) {
                          final bar = bars[index];
                          final bool isActive = bar.estado;
                          final accentColor = isActive ? const Color(0xFF00F0FF) : Colors.redAccent;

                          return Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentColor.withOpacity(0.15),
                                width: 1.2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.03),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Columna 1: Avatar/Logo (Círculo simétrico con aro de estado de 1.0 de grosor)
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: accentColor.withOpacity(0.3),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Colors.black26,
                                        backgroundImage: (bar.logoUrl != null && bar.logoUrl!.isNotEmpty)
                                            ? NetworkImage(bar.logoUrl!)
                                            : null,
                                        child: (bar.logoUrl == null || bar.logoUrl!.isEmpty)
                                            ? Icon(
                                                Icons.local_bar,
                                                color: accentColor,
                                                size: 20,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Columna 2: Detalles en texto (Nombre y Ciudad • Moneda únicamente)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Línea 1: Nombre de la Sucursal
                                          Text(
                                            bar.nombre,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),

                                          // Línea 2: Ciudad • Moneda
                                          Text(
                                            '${bar.ciudad ?? "Sin Ciudad"}  •  ${bar.monedaIso}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                                              height: 1.0,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Columna 3: Iconos y Switch en una sola Fila Horizontal
                                    // Orden: Ingresar (Entrar) -> Editar -> Switch (Activar y desactivar)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        // 1. Botón Ingresar (Tap Target amplio de 8.0)
                                        Tooltip(
                                          message: 'Ingresar a Terminal',
                                          child: InkWell(
                                            onTap: () {
                                              ref.read(authProvider.notifier).selectBar(bar.id);
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(Icons.login, size: 18, color: Color(0xFF00F0FF)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // 2. Botón Editar (Tap Target amplio de 8.0)
                                        Tooltip(
                                          message: 'Editar Configuración',
                                          child: InkWell(
                                            onTap: () {
                                              showResponsiveDialog(
                                                context: context,
                                                maxWidth: 550,
                                                child: BarFormDialog(
                                                  bar: bar,
                                                  onSaved: () {
                                                    ref.refresh(barsFutureProvider);
                                                  },
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // 3. Switch de Habilitar/Deshabilitar rápido (con confirmación de bottom sheet)
                                        Tooltip(
                                          message: isActive ? 'Deshabilitar' : 'Habilitar',
                                          child: SizedBox(
                                            height: 24,
                                            width: 38,
                                            child: Transform.scale(
                                              scale: 0.75,
                                              child: Switch(
                                                value: isActive,
                                                activeColor: const Color(0xFF00F0FF),
                                                activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.3),
                                                inactiveThumbColor: Colors.grey,
                                                inactiveTrackColor: Colors.white10,
                                                onChanged: (val) async {
                                                  final confirm = await showBarStatusConfirmationBottomSheet(
                                                    context: context,
                                                    bar: bar,
                                                    targetState: val,
                                                  );
                                                  if (confirm == true) {
                                                    _toggleBarEstado(bar, val);
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48.0,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Error al cargar las sucursales',
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            err.toString(),
                            style: theme.textTheme.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () => ref.refresh(barsFutureProvider),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {bool isFirst = false, bool isLast = false}) {
    final bool isSelected = _statusFilter == value;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          left: isFirst ? 0.0 : 4.0,
          right: isLast ? 0.0 : 4.0,
        ),
        child: InkWell(
          onTap: () {
            setState(() => _statusFilter = value);
          },
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00F0FF).withOpacity(0.15) : const Color(0xFF22252A),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isSelected ? const Color(0xFF00F0FF).withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? const Color(0xFF00F0FF) : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
