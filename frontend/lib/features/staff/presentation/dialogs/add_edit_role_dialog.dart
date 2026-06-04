import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../admin/data/models/role_model.dart';
import '../../../admin/providers/staff_provider.dart';
import '../../../../core/widgets/styled_text_field.dart';

Future<void> showAddEditRoleDialog({
  required BuildContext context,
  required WidgetRef ref,
  RoleModel? role,
}) async {
  final bool isEdit = role != null;

  final nameController = TextEditingController(text: role?.nombre);
  List<String> selectedPermissionIds = role?.permisos.map((p) => p.id).toList() ?? [];

  bool isSaving = false;

  // Load available permissions
  final permissionsAsync = ref.read(permissionsListProvider);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final viewInsets = MediaQuery.of(context).viewInsets;
          final size = MediaQuery.of(context).size;
          final maxModalHeight = size.height * 0.8;

          return Container(
            constraints: BoxConstraints(
              maxHeight: maxModalHeight,
            ),
            margin: EdgeInsets.only(bottom: viewInsets.bottom),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024), // Level 2 Modal
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Editar Rol' : 'Nuevo Rol Personalizado',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.close, color: Colors.white54, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'NOMBRE DEL ROL',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFB9CACB),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StyledTextField(
                          controller: nameController,
                          hintText: 'Ej. Ayudante de Barra',
                          icon: Icons.security,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ASIGNAR PERMISOS DE ACCESO',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFB9CACB),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // List of permissions
                        Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0E12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: permissionsAsync.when(
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    16 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16181C),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.0)),
                  ),
                  child: Row(
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
                                if (nameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor escribe un nombre para el rol'),
                                      backgroundColor: Colors.orangeAccent,
                                    ),
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

                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEdit
                                          ? 'Rol actualizado correctamente'
                                          : 'Rol personalizado creado con éxito'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error al guardar el rol personalizado'),
                                      backgroundColor: Colors.redAccent,
                                    ),
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
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
