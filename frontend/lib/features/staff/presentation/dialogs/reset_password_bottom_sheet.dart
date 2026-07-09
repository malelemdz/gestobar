import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/models/user_model.dart';
import '../../../admin/providers/staff_provider.dart';
import '../../../../core/widgets/styled_text_field.dart';
import '../../../../core/widgets/responsive_modal.dart';
import '../../../../core/widgets/custom_toast.dart';

Future<void> showResetPasswordBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required UserModel user,
}) async {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

  Widget buildModalContent(BuildContext context, StateSetter setModalState, bool isDialog) {
    final Widget formBody = SingleChildScrollView(
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
                    CustomToast.show(
                      context,
                      message: 'Contraseña restablecida con éxito',
                      type: ToastType.success,
                    );
                    Navigator.pop(context);
                  } else {
                    setModalState(() {
                      isSaving = false;
                    });
                    CustomToast.show(
                      context,
                      message: 'Error al restablecer la contraseña',
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
                  'RESTABLECER',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0c0e12),
                  ),
                ),
        ),
      ],
    );

    return ResponsiveModalContainer(
      title: 'Restablecer Contraseña',
      isDialog: isDialog,
      footer: footer,
      child: formBody,
    );
  }

  await showResponsiveDialog(
    context: context,
    maxWidth: 500,
    child: StatefulBuilder(
      builder: (context, setModalState) {
        return buildModalContent(context, setModalState, isTabletLandscape);
      },
    ),
  );
}
