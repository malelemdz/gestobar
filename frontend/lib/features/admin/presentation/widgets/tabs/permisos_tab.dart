import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/theme/app_theme.dart';
import '../config_bento_card.dart';

class PermisosTab extends StatelessWidget {
  final Map<String, bool> permittedTabs;
  final void Function(String, bool) onTabToggle;

  static const List<Map<String, String>> tabMetadata = [
    {
      'id': 'identidad',
      'title': 'Identidad',
      'description': 'Logo, nombre comercial, dirección física, ubicación y contacto de WhatsApp.',
    },
    {
      'id': 'redes',
      'title': 'Redes Sociales',
      'description': 'Enlaces a Facebook, Instagram y TikTok de la sucursal.',
    },
    {
      'id': 'operaciones',
      'title': 'Operaciones',
      'description': 'Configuración de la moneda local, zona horaria y decimales de visualización.',
    },
    {
      'id': 'horario',
      'title': 'Horario Semanal',
      'description': 'Días laborales de apertura y rangos horarios de atención.',
    },
    {
      'id': 'compania',
      'title': 'Damas de Compañía',
      'description': 'Configuración del módulo, tarifas y porcentajes de comisiones por venta.',
    },
    {
      'id': 'tarifas',
      'title': 'Gestión de Precios',
      'description': 'Administración de tarifas de precios ilimitadas (ej. General, VIP).',
    },
  ];

  const PermisosTab({
    super.key,
    required this.permittedTabs,
    required this.onTabToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConfigBentoCard(
                title: 'Control de Acceso Admin',
                description: 'Activa o desactiva qué secciones de configuración del bar actual estarán visibles para los administradores locales.',
                icon: Icons.admin_panel_settings_outlined,
                child: Column(
                  children: tabMetadata.map((meta) {
                    final String id = meta['id']!;
                    final String title = meta['title']!;
                    final String description = meta['description']!;
                    final bool isEnabled = permittedTabs[id] ?? true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.liquidSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEnabled
                              ? const Color(0xFF00F0FF).withOpacity(0.15)
                              : AppTheme.liquidOutline.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.poppins(
                                    color: isEnabled ? Colors.white : Colors.white30,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: GoogleFonts.poppins(
                                    color: isEnabled ? Colors.white54 : Colors.white24,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Transform.scale(
                            scale: 0.85,
                            child: Switch.adaptive(
                              value: isEnabled,
                              activeColor: const Color(0xFF00F0FF),
                              onChanged: (val) => onTabToggle(id, val),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x1A00F0FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x3300F0FF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF00F0FF), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nota: Los cambios son específicos para esta sucursal. Los administradores locales no tendrán acceso a las secciones que deshabilites.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF00F0FF),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
