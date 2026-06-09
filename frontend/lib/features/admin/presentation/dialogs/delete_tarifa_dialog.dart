import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/features/admin/data/models/tarifa_model.dart';
import 'package:gestobar/features/admin/providers/tarifas_provider.dart';

import 'package:gestobar/core/widgets/custom_toast.dart';

class DeleteTarifaDialog extends ConsumerWidget {
  final TarifaModel tarifa;

  const DeleteTarifaDialog({
    super.key,
    required this.tarifa,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: Text(
          'Eliminar Tarifa',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la tarifa "${tarifa.nombre}"? Esto eliminará todos los precios asignados a esta tarifa de forma permanente.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(tarifasRepositoryProvider);
              try {
                await repo.deleteTarifa(tarifa.id);
                ref.invalidate(barTarifasProvider);
                if (context.mounted) {
                  CustomToast.show(
                    context,
                    message: 'Tarifa eliminada con éxito',
                    type: ToastType.success,
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  CustomToast.show(
                    context,
                    message: 'Error al eliminar tarifa: $e',
                    type: ToastType.error,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
