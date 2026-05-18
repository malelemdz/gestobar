import 'package:flutter/material.dart';

class DamaPage extends StatelessWidget {
  const DamaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 64.0, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 16.0),
          Text(
            'Panel de Comisiones e Invitaciones',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Consulta tus comisiones acumuladas del turno actual en tiempo real.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
