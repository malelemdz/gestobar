import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../admin/data/models/role_model.dart';
import '../../../admin/providers/staff_provider.dart';
import '../../../../core/widgets/styled_text_field.dart';
import '../../../../core/widgets/responsive_modal.dart';
import '../../../../core/widgets/custom_toast.dart';

Future<void> showAddEditRoleDialog({
  required BuildContext context,
  required WidgetRef ref,
  RoleModel? role,
}) async {
  ref.invalidate(permissionsListProvider);
  final bool isEdit = role != null;

  final nameController = TextEditingController(text: role?.nombre);
  List<String> selectedPermissionIds = role?.permisos.map((p) => p.id).toList() ?? [];

  bool isSaving = false;

  final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

  Widget buildModalContent(BuildContext context, StateSetter setModalState, bool isDialog) {
    final Widget roleBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'NOMBRE DEL ROL',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              StyledTextField(
                controller: nameController,
                hintText: 'Ej. Ayudante de Barra',
                icon: Icons.security,
              ),
              const SizedBox(height: 16),
              Text(
                'ASIGNAR PERMISOS DE ACCESO',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 380),
              decoration: BoxDecoration(
                color: const Color(0xFF22252A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.0),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final permissionsAsyncVal = ref.watch(permissionsListProvider);
                  return permissionsAsyncVal.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                    ),
                    data: (permissions) {
                      if (permissions.isEmpty) {
                        return Center(
                          child: Text(
                            'No hay permisos disponibles',
                            style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: permissions.length,
                        itemBuilder: (context, index) {
                          final perm = permissions[index];
                          final isChecked = selectedPermissionIds.contains(perm.id);

                          return Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: Colors.white24,
                            ),
                            child: CheckboxListTile(
                              dense: true,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              title: Text(
                                perm.nombre,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              value: isChecked,
                              activeColor: const Color(0xFF00F0FF),
                              checkColor: Colors.black,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedPermissionIds.add(perm.id);
                                  } else {
                                    selectedPermissionIds.remove(perm.id);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );

    final Widget footer = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF),
            foregroundColor: const Color(0xFF0C0E12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            elevation: 0,
          ),
          onPressed: isSaving
              ? null
              : () async {
                  final navigator = Navigator.of(context);

                  if (nameController.text.trim().isEmpty) {
                    CustomToast.show(
                      context,
                      message: 'Por favor escribe un nombre para el rol',
                      type: ToastType.warning,
                    );
                    return;
                  }

                  setModalState(() {
                    isSaving = true;
                  });

                  bool success;
                  if (isEdit) {
                    success = await ref
                        .read(rolesListProvider.notifier)
                        .updateRole(
                          role.id,
                          nameController.text.trim(),
                          selectedPermissionIds,
                        );
                  } else {
                    success = await ref
                        .read(rolesListProvider.notifier)
                        .createRole(
                          nameController.text.trim(),
                          selectedPermissionIds,
                        );
                  }

                  if (success) {
                    CustomToast.show(
                      context,
                      message: isEdit
                          ? 'Rol actualizado correctamente'
                          : 'Rol personalizado creado con éxito',
                      type: ToastType.success,
                    );
                    navigator.pop();
                  } else {
                    setModalState(() {
                      isSaving = false;
                    });
                    CustomToast.show(
                      context,
                      message: 'Error al guardar el rol personalizado',
                      type: ToastType.error,
                    );
                  }
                },
          child: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
              : Text(
                  isEdit ? 'GUARDAR ROL' : 'CREAR ROL',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0c0e12),
                  ),
                ),
        ),
      ],
    );

    return ResponsiveModalContainer(
      title: isEdit ? 'Editar Rol' : 'Nuevo Rol Personalizado',
      isDialog: isDialog,
      footer: footer,
      child: roleBody,
    );
  }

  await showResponsiveDialog(
    context: context,
    maxWidth: 550,
    child: StatefulBuilder(
      builder: (context, setModalState) {
        return buildModalContent(context, setModalState, isTabletLandscape);
      },
    ),
  );
}
