import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../providers/auditoria_provider.dart';
import '../data/models/auditoria_model.dart';

class AuditoriaPage extends ConsumerWidget {
  const AuditoriaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auditoriaAsync = ref.watch(auditoriaListProvider);

    return Scaffold(
      backgroundColor: AppTheme.liquidBg,
      appBar: AppBar(
        backgroundColor: AppTheme.liquidBg,
        elevation: 0,
        title: Text(
          'Bitácora del Sistema',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.refresh(auditoriaListProvider),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white70),
            onPressed: () {
              // TODO: Implementar menú de filtros visual
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Filtros próximamente...')));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.liquidPrimary,
        backgroundColor: const Color(0xFF1E2024),
        onRefresh: () async {
          ref.invalidate(auditoriaListProvider);
          await ref.read(auditoriaListProvider.future);
        },
        child: auditoriaAsync.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16.0),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ShimmerPlaceholder(
                width: double.infinity,
                height: 120,
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
          error: (err, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 150,
              child: Center(
                child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
          data: (logs) {
            if (logs.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 150,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text('No hay registros en la bitácora aún', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogCard(log, theme);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(AuditoriaModel log, ThemeData theme) {
    final format = DateFormat('dd MMM yyyy, HH:mm:ss');
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
                log.accion.toUpperCase(),
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
                  '${log.usuarioNombre ?? "Usuario"} (${log.rolNombre})',
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
          if (log.dispositivo != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.devices, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  log.dispositivo!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

