import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import 'package:gestobar/features/admin/data/models/tarifa_model.dart';
import 'package:gestobar/features/admin/providers/tarifas_provider.dart';

import 'package:gestobar/core/widgets/custom_toast.dart';

class TarifaDialog extends ConsumerStatefulWidget {
  final String barId;
  final TarifaModel? tarifa;

  const TarifaDialog({
    super.key,
    required this.barId,
    this.tarifa,
  });

  @override
  ConsumerState<TarifaDialog> createState() => _TarifaDialogState();
}

class _TarifaDialogState extends ConsumerState<TarifaDialog> {
  late TextEditingController _nameController;
  late bool _esDefault;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tarifa?.nombre ?? '');
    _esDefault = widget.tarifa?.esDefault ?? false;
    _activo = widget.tarifa?.activo ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: Text(
          widget.tarifa == null ? 'Nueva Tarifa' : 'Editar Tarifa',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Container(
          width: 320,
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOMBRE',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.liquidOnSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _nameController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ej. VIP, Especial...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TARIFA POR DEFECTO',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.liquidOnSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: _esDefault,
                    activeColor: const Color(0xFF00F0FF),
                    onChanged: (val) {
                      setState(() {
                        _esDefault = val;
                        // Si se fuerza como default, debe estar activa obligatoriamente
                        if (_esDefault) _activo = true;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TARIFA ACTIVA',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.liquidOnSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: _activo,
                    activeColor: const Color(0xFF00F0FF),
                    onChanged: _esDefault
                        ? null // Si es default, no se puede desactivar
                        : (val) {
                            setState(() {
                              _activo = val;
                            });
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.trim().isEmpty) return;

              final repo = ref.read(tarifasRepositoryProvider);
              try {
                if (widget.tarifa == null) {
                  await repo.createTarifa(
                    widget.barId,
                    _nameController.text.trim(),
                    _esDefault,
                    _activo,
                  );
                } else {
                  await repo.updateTarifa(
                    widget.tarifa!.id,
                    _nameController.text.trim(),
                    _esDefault,
                    _activo,
                  );
                }
                ref.invalidate(barTarifasProvider);
                if (context.mounted) {
                  CustomToast.show(
                    context,
                    message: widget.tarifa == null
                        ? 'Tarifa creada con éxito'
                        : 'Tarifa actualizada con éxito',
                    type: ToastType.success,
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  CustomToast.show(
                    context,
                    message: 'Error al guardar tarifa: $e',
                    type: ToastType.error,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Guardar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0c0e12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
