import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/models/user_model.dart';
import '../dialogs/auditoria_filter_selectors.dart';
import '../../providers/auditoria_provider.dart';
import '../../providers/staff_provider.dart';
import '../utils/auditoria_formatters.dart';
import 'custom_date_range_picker.dart';

class AuditoriaFilterCapsules extends ConsumerWidget {
  const AuditoriaFilterCapsules({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(auditoriaFiltersProvider);
    final staffAsync = ref.watch(staffListProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 12.0),
      child: Row(
        children: [
          _buildUserFilterCapsule(context, ref, filters, staffAsync),
          const SizedBox(width: 8),
          _buildActionFilterCapsule(context, ref, filters),
          const SizedBox(width: 8),
          _buildModuleFilterCapsule(context, ref, filters),
          const SizedBox(width: 8),
          _buildDateFilterCapsule(context, ref, filters),
        ],
      ),
    );
  }

  Widget _buildUserFilterCapsule(
    BuildContext context,
    WidgetRef ref,
    Map<String, String?> filters,
    AsyncValue<List<UserModel>> staffAsync,
  ) {
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
      onTap: () => showUserSelector(context, ref),
      onClear: () {
        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
          ...state,
          'usuarioId': null,
        });
      },
    );
  }

  Widget _buildActionFilterCapsule(
    BuildContext context,
    WidgetRef ref,
    Map<String, String?> filters,
  ) {
    final selectedAction = filters['accion'];
    final isSelected = selectedAction != null;

    return _buildFilterChip(
      label: isSelected ? AuditoriaFormatters.formatAction(selectedAction) : 'Acción',
      isSelected: isSelected,
      onTap: () => showActionSelector(context, ref),
      onClear: () {
        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
          ...state,
          'accion': null,
        });
      },
    );
  }

  Widget _buildModuleFilterCapsule(
    BuildContext context,
    WidgetRef ref,
    Map<String, String?> filters,
  ) {
    final selectedModule = filters['modulo'];
    final isSelected = selectedModule != null;

    return _buildFilterChip(
      label: selectedModule ?? 'Módulo',
      isSelected: isSelected,
      onTap: () => showModuleSelector(context, ref),
      onClear: () {
        ref.read(auditoriaFiltersProvider.notifier).update((state) => {
          ...state,
          'modulo': null,
        });
      },
    );
  }

  Widget _buildDateFilterCapsule(
    BuildContext context,
    WidgetRef ref,
    Map<String, String?> filters,
  ) {
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
      onTap: () => _selectDateRange(context, ref),
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
          color: isSelected ? AppTheme.liquidPrimary : AppTheme.liquidSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? AppTheme.liquidPrimary
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
                color: isSelected ? const Color(0xFF14161A) : Colors.white.withOpacity(0.6),
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
                  color: Color(0xFF14161A),
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
}
