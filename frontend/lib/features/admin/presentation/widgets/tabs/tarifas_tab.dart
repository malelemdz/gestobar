import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/features/admin/data/models/tarifa_model.dart';
import '../config_bento_card.dart';

class TarifasTab extends StatelessWidget {
  final String? selectedTarifaCompaniaId;
  final AsyncValue<List<TarifaModel>> tarifasState;
  final void Function(TarifaModel?) onOpenTarifaDialog;
  final void Function(TarifaModel) onDeleteTarifa;

  const TarifasTab({
    super.key,
    required this.selectedTarifaCompaniaId,
    required this.tarifasState,
    required this.onOpenTarifaDialog,
    required this.onDeleteTarifa,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ConfigBentoCard(
            title: 'Gestión de Precios',
            description: 'Crea precios infinitos (ej. Normal, VIP, Compañía) para tus productos.',
            icon: Icons.payments_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tarifasState.when(
                  data: (tarifas) {
                    if (tarifas.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          'No hay tarifas creadas. Crea una para comenzar.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tarifas.length,
                      itemBuilder: (context, index) {
                        final tarifa = tarifas[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.liquidSurfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tarifa.nombre,
                                    style: GoogleFonts.poppins(
                                      color: tarifa.activo ? Colors.white : Colors.white30,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      decoration: tarifa.activo ? null : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  if (tarifa.esDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00F0FF).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF00F0FF),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (tarifa.id == selectedTarifaCompaniaId) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.pinkAccent.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        'Dama',
                                        style: GoogleFonts.poppins(
                                          color: Colors.pinkAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF00F0FF), size: 18),
                                    onPressed: () => onOpenTarifaDialog(tarifa),
                                  ),
                                  if (!tarifa.esDefault)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      onPressed: () => onDeleteTarifa(tarifa),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                  ),
                  error: (err, _) => Text(
                    'Error al cargar tarifas: $err',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => onOpenTarifaDialog(null),
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF0c0e12)),
                  label: Text(
                    'Nueva Tarifa',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0c0e12),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
