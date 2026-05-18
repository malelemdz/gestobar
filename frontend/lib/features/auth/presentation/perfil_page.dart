import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 16.0),
          CircleAvatar(
            radius: 50.0,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Text(
              user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 36.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            user.nombre,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Chip(
            label: Text(user.rolNombre.toUpperCase()),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 40.0),
          _buildProfileItem(context, Icons.phone_android, 'Celular', (user.celular != null && user.celular!.isNotEmpty) ? user.celular! : 'No registrado'),
          _buildProfileItem(context, Icons.badge_outlined, 'DNI / Documento', 'No registrado'),
          _buildProfileItem(context, Icons.flag_outlined, 'País / Región', 'Bolivia'),
          const SizedBox(height: 32.0),
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Restablecer Contraseña'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Acción disponible en la siguiente fase de desarrollo.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20.0),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
