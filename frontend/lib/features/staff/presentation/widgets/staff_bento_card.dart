import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/models/user_model.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';
import '../../../admin/providers/staff_provider.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/constants/api_constants.dart';

class StaffBentoCard extends ConsumerWidget {
  final UserModel user;
  final Future<bool?> Function(BuildContext, UserModel, bool) onShowStatusConfirmation;
  final void Function(BuildContext, UserModel) onShowResetPassword;
  final void Function(BuildContext, UserModel?) onShowAddEditStaff;

  const StaffBentoCard({
    super.key,
    required this.user,
    required this.onShowStatusConfirmation,
    required this.onShowResetPassword,
    required this.onShowAddEditStaff,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accentColor = user.estado ? const Color(0xFF00F0FF) : Colors.redAccent;
    final authState = ref.watch(authProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isMe = currentUser?.id == user.id;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.15),
          width: 1.2,
        ),
        boxShadow: user.estado
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.03),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Column 1: Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withOpacity(0.4),
                          width: 2.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.black26,
                        backgroundImage: (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                            ? NetworkImage(ApiConstants.resolveImageUrl(user.fotoUrl)!)
                            : null,
                        child: (user.fotoUrl == null || user.fotoUrl!.isEmpty)
                            ? Text(
                                user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Column 2: Text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Line 1: Nombre completo
                    Text(
                      '${user.nombre} ${user.apellido}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Line 2: Username and Role Chip side-by-side!
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '@${user.username.toLowerCase()}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              height: 1.0,
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: accentColor.withOpacity(0.3), width: 0.8),
                          ),
                          child: Text(
                            user.rolNombre.toUpperCase(),
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              height: 1.0,
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Line 3: DNI
                    Text(
                      user.identificacion?.isNotEmpty == true ? 'DNI: ${user.identificacion!}' : 'DNI No reg.',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                        height: 1.0,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Column 3: Switch and Action buttons stacked on the right!
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 38,
                    child: Transform.scale(
                      scale: 0.65,
                      child: Switch(
                        value: user.estado,
                        activeColor: const Color(0xFF00F0FF),
                        activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.white10,
                        onChanged: (val) async {
                          if (isMe && !val) {
                            CustomToast.show(
                              context,
                              message: 'No puedes deshabilitar tu propio usuario.',
                              type: ToastType.warning,
                            );
                            return;
                          }
                          final confirm = await onShowStatusConfirmation(context, user, val);
                          if (confirm == true) {
                            final success = await ref
                                .read(staffListProvider.notifier)
                                .toggleStaffStatus(user.id, val);
                            if (context.mounted) {
                              if (success) {
                                CustomToast.show(
                                  context,
                                  message: val
                                      ? 'Usuario habilitado con éxito'
                                      : 'Usuario deshabilitado con éxito',
                                  type: ToastType.success,
                                );
                              } else {
                                CustomToast.show(
                                  context,
                                  message: 'Error al cambiar estado del usuario',
                                  type: ToastType.error,
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Action Buttons under Switch
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Cambiar Contraseña',
                        child: InkWell(
                          onTap: () => onShowResetPassword(context, user),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.vpn_key_outlined, size: 16, color: Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: 'Editar',
                        child: InkWell(
                          onTap: () => onShowAddEditStaff(context, user),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.edit_outlined, size: 16, color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
