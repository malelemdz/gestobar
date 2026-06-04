import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/models/user_model.dart';
import '../../../admin/providers/staff_provider.dart';
import '../../../../core/widgets/styled_text_field.dart';

Future<void> showResetPasswordBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required UserModel user,
}) async {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final viewInsets = MediaQuery.of(context).viewInsets;
          final size = MediaQuery.of(context).size;
          final maxModalHeight = size.height * 0.7;

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
                        'Restablecer Contraseña',
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
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Escribe una nueva contraseña para ${user.nombre}. El usuario deberá usar esta clave para ingresar en su siguiente inicio de sesión.',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'NUEVA CONTRASEÑA',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9CACB),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StyledTextField(
                            controller: passwordController,
                            hintText: 'Mínimo 6 caracteres',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es obligatoria';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'CONFIRMAR NUEVA CONTRASEÑA',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9CACB),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StyledTextField(
                            controller: confirmPasswordController,
                            hintText: 'Repite la nueva contraseña',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirma la contraseña';
                              }
                              if (value != passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
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
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                setModalState(() {
                                  isSaving = true;
                                });

                                final success = await ref
                                    .read(staffListProvider.notifier)
                                    .updateStaff(user.id, {
                                  'password': passwordController.text.trim(),
                                });

                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contraseña restablecida con éxito'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Error al restablecer la contraseña'),
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
                                'RESTABLECER',
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
