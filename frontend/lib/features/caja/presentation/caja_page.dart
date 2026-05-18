import 'package:flutter/material.dart';

class CajaPage extends StatelessWidget {
  const CajaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments, size: 64.0, color: theme.colorScheme.secondary.withOpacity(0.5)),
          const SizedBox(height: 16.0),
          Text(
            'Módulo de Control de Caja',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Disponible en la Fase 3: Aperturas, Cierres y Billeteo.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
