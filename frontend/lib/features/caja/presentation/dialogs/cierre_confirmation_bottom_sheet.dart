import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/local_db/hive_entities/sync_queue_hive.dart';
import '../../../../core/local_db/hive_provider.dart';
import '../../../../core/theme/app_theme.dart';

class CierreConfirmationBottomSheet extends ConsumerStatefulWidget {
  final String cajaId;
  final VoidCallback onConfirm;
  final bool isDialog;

  const CierreConfirmationBottomSheet({
    super.key,
    required this.cajaId,
    required this.onConfirm,
    this.isDialog = false,
  });

  @override
  ConsumerState<CierreConfirmationBottomSheet> createState() => _CierreConfirmationBottomSheetState();
}

class _CierreConfirmationBottomSheetState extends ConsumerState<CierreConfirmationBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Verificar cola de sincronización de Hive
    final syncBox = Hive.box<SyncQueueTaskHive>('sync_queue');
    final bool hasUnsynced = syncBox.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: widget.isDialog
            ? BorderRadius.circular(24.0)
            : const BorderRadius.vertical(top: Radius.circular(16.0)),
        border: widget.isDialog
            ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confirmar Cierre de Turno',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Esta acción dará por finalizado el turno activo actual de la caja. El sistema registrará los balances y comisiones generadas de forma automática.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12.0),

          if (hasUnsynced) ...[
            // Bloqueo de seguridad dinámico con botón para sincronizar ahora
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.colorDanger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.colorDanger.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.colorDanger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'BLOQUEO DE SEGURIDAD',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.colorDanger,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tienes ${syncBox.length} pedido(s) cobrados localmente que aún no suben al servidor. Debes estar conectado a internet y sincronizarlos antes de poder cerrar el turno.',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync, size: 16),
                    label: const Text('INTENTAR SINCRONIZAR AHORA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.colorDanger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              final syncWorker = ref.read(syncWorkerProvider);
                              await syncWorker.processQueue();
                            } catch (_) {
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
          ],

          // Botones de Acción
          Center(
            child: SizedBox(
              width: widget.isDialog ? 360.0 : double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: Text('CANCELAR', style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasUnsynced ? Colors.white10 : const Color(0xFF7000FF),
                        foregroundColor: hasUnsynced ? Colors.white24 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: hasUnsynced || _isLoading
                          ? null
                          : () {
                              Navigator.pop(context); // Cerrar bottom sheet
                              widget.onConfirm();
                            },
                      child: Text('CONFIRMAR CIERRE', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
