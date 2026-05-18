import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuditoriaPage extends StatelessWidget {
  const AuditoriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security, size: 64.0, color: AppTheme.colorWarning.withOpacity(0.5)),
          const SizedBox(height: 16.0),
          Text(
            'Módulo de Auditoría de Sistemas',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Registro completo de trazabilidad multi-tenant en tiempo real.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
