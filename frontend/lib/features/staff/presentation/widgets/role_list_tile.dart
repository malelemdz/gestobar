import 'package:flutter/material.dart';
import '../../../admin/data/models/role_model.dart';

class RoleListTile extends StatelessWidget {
  final RoleModel role;
  final Color roleColor;
  final void Function(BuildContext, RoleModel) onShowAddEditRole;
  final void Function(BuildContext, RoleModel) onShowDeleteRoleConfirmation;

  const RoleListTile({
    super.key,
    required this.role,
    required this.roleColor,
    required this.onShowAddEditRole,
    required this.onShowDeleteRoleConfirmation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGlobal = role.barId == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              role.nombre.toUpperCase(),
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isGlobal ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isGlobal ? Colors.blue.withOpacity(0.3) : Colors.purple.withOpacity(0.3),
                  width: 0.6,
                ),
              ),
              child: Text(
                isGlobal ? 'SISTEMA' : 'PROPIO',
                style: TextStyle(
                  color: isGlobal ? Colors.blue : Colors.purpleAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${role.permisos.length} permisos asignados',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 12),
        ),
        trailing: isGlobal
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
                    onPressed: () => onShowAddEditRole(context, role),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: () => onShowDeleteRoleConfirmation(context, role),
                  ),
                ],
              ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: role.permisos.isEmpty
                    ? [
                        Text(
                          'Sin permisos asociados.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 12),
                        )
                      ]
                    : role.permisos.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white10, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 10, color: Color(0xFF00F0FF)),
                              const SizedBox(width: 4),
                              Text(
                                p.nombre,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
