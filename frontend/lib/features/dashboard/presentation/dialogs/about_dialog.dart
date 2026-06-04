import 'package:flutter/material.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 10.0),
          const Text('Acerca de Gestobar'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/icon/isotipo.png', width: 40.0, height: 40.0),
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Gestobar SaaS v1.0.0',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Plataforma de Alta Velocidad para Hostelería',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10.0),
                ),
              ],
            ),
          ),
          const Divider(height: 24.0),
          Text(
            'Desarrollado con dedicación para ofrecer el máximo rendimiento en flujos de trabajo de bares, pubs y discotecas bajo entornos de alta exigencia.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.0),
          ),
          const SizedBox(height: 16.0),
          Text(
            '© 2026 Antigravity Labs. Todos los derechos reservados.',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9.0,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Entendido',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
