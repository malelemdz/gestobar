import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/features/admin/data/models/tarifa_model.dart';
import '../config_bento_card.dart';
import '../config_dropdown_field.dart';
import '../config_text_field.dart';

class CompaniaTab extends StatelessWidget {
  final bool moduloDamasActivo;
  final String? selectedTarifaCompaniaId;
  final TextEditingController comisionCtrl;
  final AsyncValue<List<TarifaModel>> tarifasState;
  final void Function(bool) onModuloDamasActivoChanged;
  final void Function(String?) onSelectedTarifaCompaniaIdChanged;

  const CompaniaTab({
    super.key,
    required this.moduloDamasActivo,
    required this.selectedTarifaCompaniaId,
    required this.comisionCtrl,
    required this.tarifasState,
    required this.onModuloDamasActivoChanged,
    required this.onSelectedTarifaCompaniaIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ConfigBentoCard(
            title: 'Damas de Compañía',
            description: 'Habilita tickets y comisiones.',
            icon: Icons.people_alt_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch.adaptive(
                        value: moduloDamasActivo,
                        activeColor: AppTheme.liquidPrimary,
                        onChanged: onModuloDamasActivoChanged,
                      ),
                    ),
                  ],
                ),
                if (moduloDamasActivo) ...[
                  const SizedBox(height: 16),
                  tarifasState.when(
                    data: (tarifas) {
                      final nonDefaultTarifas = tarifas.where((t) => !t.esDefault).toList();
                      // Asegurar que el valor seleccionado exista en las opciones para evitar errores en DropdownButton
                      final String? dropdownValue = nonDefaultTarifas.any((t) => t.id == selectedTarifaCompaniaId)
                          ? selectedTarifaCompaniaId
                          : null;

                      return ConfigDropdownField<String?>(
                        label: 'Tarifa de Compañía',
                        value: dropdownValue,
                        items: nonDefaultTarifas
                            .map((t) => DropdownMenuItem<String?>(
                                  value: t.id,
                                  child: Text(t.nombre),
                                ))
                            .toList(),
                        onChanged: onSelectedTarifaCompaniaIdChanged,
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Error al cargar tarifas: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConfigTextField(
                    label: 'Comisión por Venta (%)',
                    controller: comisionCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    suffixText: '%',
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      final num = int.tryParse(v);
                      if (num == null || num < 1 || num > 99) return 'De 1 a 99';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
