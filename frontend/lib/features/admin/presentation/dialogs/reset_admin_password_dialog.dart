import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/network/dio_client.dart';
import 'package:gestobar/core/widgets/custom_toast.dart';
import 'package:gestobar/core/widgets/responsive_modal.dart';
import 'package:gestobar/core/widgets/styled_text_field.dart';
import 'package:gestobar/features/auth/models/user_model.dart';
import 'package:dio/dio.dart';

class ResetAdminPasswordDialog extends ConsumerStatefulWidget {
  final UserModel admin;
  final VoidCallback onSaved;

  const ResetAdminPasswordDialog({
    super.key,
    required this.admin,
    required this.onSaved,
  });

  @override
  ConsumerState<ResetAdminPasswordDialog> createState() => _ResetAdminPasswordDialogState();
}

class _ResetAdminPasswordDialogState extends ConsumerState<ResetAdminPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/users/${widget.admin.id}', data: {
        'password': _passwordCtrl.text.trim(),
      });

      if (mounted) {
        CustomToast.show(context, message: 'Contraseña restablecida con éxito', type: ToastType.success);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        if (e is DioException) {
          final serverMessage = e.response?.data?['message'];
          if (serverMessage != null) errorMsg = serverMessage.toString();
        }
        CustomToast.show(context, message: 'Error al restablecer la contraseña: $errorMsg', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 720;

    return ResponsiveModalContainer(
      title: 'Restablecer Contraseña',
      subtitle: 'Ingresa una nueva contraseña para ${widget.admin.nombre} ${widget.admin.apellido}',
      isDialog: isTablet,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7000FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Restablecer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CREAR NUEVAS CREDENCIALES', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
              const SizedBox(height: 12),
              
              StyledTextField(
                controller: _passwordCtrl,
                hintText: 'Nueva contraseña',
                isPassword: true,
                icon: Icons.lock_outline,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (val.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              StyledTextField(
                controller: _confirmPasswordCtrl,
                hintText: 'Confirmar contraseña',
                isPassword: true,
                icon: Icons.lock,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (val != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
