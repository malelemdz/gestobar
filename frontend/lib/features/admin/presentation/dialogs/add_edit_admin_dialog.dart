import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/network/dio_client.dart';
import 'package:gestobar/core/widgets/custom_toast.dart';
import 'package:gestobar/core/widgets/responsive_modal.dart';
import 'package:gestobar/core/widgets/styled_text_field.dart';
import 'package:gestobar/features/auth/models/user_model.dart';
import 'package:dio/dio.dart';

class AddEditAdminDialog extends ConsumerStatefulWidget {
  final UserModel? admin; // Si es null, es modo Creación
  final VoidCallback onSaved;

  const AddEditAdminDialog({
    super.key,
    this.admin,
    required this.onSaved,
  });

  @override
  ConsumerState<AddEditAdminDialog> createState() => _AddEditAdminDialogState();
}

class _AddEditAdminDialogState extends ConsumerState<AddEditAdminDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _celularCtrl;
  late final TextEditingController _passwordCtrl;

  bool _isSaving = false;
  String? _adminRoleId;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.admin?.nombre ?? '');
    _apellidoCtrl = TextEditingController(text: widget.admin?.apellido ?? '');
    _usernameCtrl = TextEditingController(text: widget.admin?.username ?? '');
    _celularCtrl = TextEditingController(text: widget.admin?.celular ?? '');
    _passwordCtrl = TextEditingController();

    if (widget.admin == null) {
      _loadAdminRoleId();
    } else {
      _isLoadingRole = false;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _usernameCtrl.dispose();
    _celularCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAdminRoleId() async {
    try {
      final dio = ref.read(dioProvider);
      final rolesRes = await dio.get('/roles');
      final List<dynamic> roles = rolesRes.data ?? [];
      for (var r in roles) {
        if (r['nombre'].toString().toUpperCase() == 'ADMIN') {
          _adminRoleId = r['id'];
          break;
        }
      }
      setState(() => _isLoadingRole = false);
    } catch (e) {
      setState(() => _isLoadingRole = false);
      if (mounted) {
        CustomToast.show(context, message: 'Error al cargar los roles del sistema', type: ToastType.error);
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    if (widget.admin == null && _adminRoleId == null) {
      CustomToast.show(context, message: 'No se pudo obtener el ID del rol de Administrador', type: ToastType.error);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);

      if (widget.admin == null) {
        // Crear nuevo Administrador
        final payload = {
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
          'celular': _celularCtrl.text.trim(),
          'rol_id': _adminRoleId,
          'estado': true,
        };

        await dio.post('/users', data: payload);
        if (mounted) {
          CustomToast.show(context, message: 'Administrador registrado con éxito', type: ToastType.success);
        }
      } else {
        // Editar Administrador existente
        final payload = {
          'nombre': _nombreCtrl.text.trim(),
          'apellido': _apellidoCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'celular': _celularCtrl.text.trim(),
        };

        await dio.patch('/users/${widget.admin!.id}', data: payload);
        if (mounted) {
          CustomToast.show(context, message: 'Perfil de administrador actualizado', type: ToastType.success);
        }
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
        CustomToast.show(context, message: 'Fallo al guardar administrador: $errorMsg', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 720;

    return ResponsiveModalContainer(
      title: widget.admin == null ? 'Registrar Administrador' : 'Editar Administrador',
      subtitle: widget.admin == null
          ? 'Crea una nueva cuenta de administrador'
          : 'Modifica los datos del administrador',
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
            onPressed: _isSaving || _isLoadingRole ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7000FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.admin == null ? 'Guardar' : 'Actualizar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      child: _isLoadingRole
          ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFF00F0FF))))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DATOS PERSONALES', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    
                    if (isTablet)
                      Row(
                        children: [
                          Expanded(
                            child: StyledTextField(
                              controller: _nombreCtrl,
                              hintText: 'Nombre',
                              icon: Icons.person,
                              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StyledTextField(
                              controller: _apellidoCtrl,
                              hintText: 'Apellido',
                              icon: Icons.person_outline,
                              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      StyledTextField(
                        controller: _nombreCtrl,
                        hintText: 'Nombre',
                        icon: Icons.person,
                        validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      StyledTextField(
                        controller: _apellidoCtrl,
                        hintText: 'Apellido',
                        icon: Icons.person_outline,
                        validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                    ],
                    const SizedBox(height: 12),

                    StyledTextField(
                      controller: _celularCtrl,
                      hintText: 'Número de Celular (Opcional)',
                      icon: Icons.phone,
                    ),
                    const SizedBox(height: 24),

                    Text('DATOS DE ACCESO', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                    const SizedBox(height: 12),

                    StyledTextField(
                      controller: _usernameCtrl,
                      hintText: 'Nombre de usuario (ej: admin_sucre)',
                      icon: Icons.alternate_email,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (val.length < 4) return 'Mínimo 4 caracteres';
                        return null;
                      },
                    ),

                    if (widget.admin == null) ...[
                      const SizedBox(height: 12),
                      StyledTextField(
                        controller: _passwordCtrl,
                        hintText: 'Contraseña de acceso',
                        isPassword: true,
                        icon: Icons.lock,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Requerido';
                          if (val.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
