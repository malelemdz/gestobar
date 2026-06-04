import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admin/data/models/role_model.dart';
import '../../../admin/providers/staff_provider.dart';

Future<void> showDeleteRoleConfirmationDialog({
  required BuildContext context,
  required WidgetRef ref,
  required RoleModel role,
}) async {
  final theme = Theme.of(context);
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E2024),
        title: const Text('¿ELIMINAR ROL?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          '¿Estás seguro de que deseas eliminar el rol "${role.nombre}"? Los usuarios que posean este rol deberán ser reasignados.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              final success = await ref.read(rolesListProvider.notifier).deleteRole(role.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rol eliminado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('ELIMINAR ROL'),
          ),
        ],
      );
    },
  );
}
