import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import '../config_bento_card.dart';
import '../config_time_picker_field.dart';

class HorarioTab extends StatelessWidget {
  final Map<String, dynamic> horarios;
  final void Function(String, bool) onDiaToggle;
  final void Function(String, String) onPickTime;

  static const List<String> dias = [
    'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'
  ];

  const HorarioTab({
    super.key,
    required this.horarios,
    required this.onDiaToggle,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: MediaQuery.of(context).size.width >= 1000
          ? const EdgeInsets.fromLTRB(0, 0, 0, 24)
          : const EdgeInsets.all(24.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ConfigBentoCard(
            title: 'Horario Semanal',
            description: 'Gestiona los días de apertura y horas de atención.',
            icon: Icons.access_time_filled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...dias.map((dia) {
                  final data = horarios[dia];
                  if (data == null) return const SizedBox();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.only(top: 0.0, bottom: 12.0, left: 16.0, right: 16.0),
                    decoration: BoxDecoration(
                      color: AppTheme.liquidSurfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.liquidOutline.withOpacity(0.3)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 400;
                        if (isMobile) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dia.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: data['abierto']
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface.withOpacity(0.4),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch.adaptive(
                                      value: data['abierto'],
                                      activeColor: AppTheme.liquidPrimary,
                                      onChanged: (v) => onDiaToggle(dia, v),
                                    ),
                                  ),
                                ],
                              ),
                              if (data['abierto']) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ConfigTimePickerField(
                                        label: 'Apertura',
                                        time: data['apertura'],
                                        onTap: () => onPickTime(dia, 'apertura'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ConfigTimePickerField(
                                        label: 'Cierre',
                                        time: data['cierre'],
                                        onTap: () => onPickTime(dia, 'cierre'),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'CERRADO',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch.adaptive(
                                            value: data['abierto'],
                                            activeColor: AppTheme.liquidPrimary,
                                            onChanged: (v) => onDiaToggle(dia, v),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          dia.toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: data['abierto']
                                                ? theme.colorScheme.onSurface
                                                : theme.colorScheme.onSurface.withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 5,
                                    child: data['abierto']
                                        ? Row(
                                            children: [
                                              Expanded(
                                                child: ConfigTimePickerField(
                                                  label: 'Apertura',
                                                  time: data['apertura'],
                                                  onTap: () => onPickTime(dia, 'apertura'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ConfigTimePickerField(
                                                  label: 'Cierre',
                                                  time: data['cierre'],
                                                  onTap: () => onPickTime(dia, 'cierre'),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: Text(
                                                'CERRADO',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant
                                                      .withOpacity(0.4),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
