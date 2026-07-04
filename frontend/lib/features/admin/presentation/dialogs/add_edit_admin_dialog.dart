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
  late final TextEditingController _dniCtrl;
  late final TextEditingController _nacionalidadCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _passwordCtrl;

  String _selectedGender = 'PREFIERO_NO_DECIRLO';
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
    _dniCtrl = TextEditingController(text: widget.admin?.identificacion ?? '');
    _nacionalidadCtrl = TextEditingController(text: widget.admin?.nacionalidad ?? 'Bolivia');
    _direccionCtrl = TextEditingController(text: widget.admin?.direccion ?? '');
    _passwordCtrl = TextEditingController();

    if (widget.admin != null) {
      _selectedGender = widget.admin!.genero ?? 'PREFIERO_NO_DECIRLO';
      _isLoadingRole = false;
    } else {
      _loadAdminRoleId();
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _usernameCtrl.dispose();
    _celularCtrl.dispose();
    _dniCtrl.dispose();
    _nacionalidadCtrl.dispose();
    _direccionCtrl.dispose();
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

      final Map<String, dynamic> payload = {
        'nombre': _nombreCtrl.text.trim(),
        'apellido': _apellidoCtrl.text.trim(),
        'username': _usernameCtrl.text.trim().toLowerCase(),
        'genero': _selectedGender,
        'celular': _celularCtrl.text.trim(),
        'identificacion': _dniCtrl.text.trim(),
        'nacionalidad': _nacionalidadCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
      };

      if (widget.admin == null) {
        // Crear nuevo Administrador
        payload['rol_id'] = _adminRoleId;
        payload['estado'] = true;
        payload['password'] = _passwordCtrl.text.trim();

        await dio.post('/users', data: payload);
        if (mounted) {
          CustomToast.show(context, message: 'Administrador registrado con éxito', type: ToastType.success);
        }
      } else {
        // Editar Administrador existente
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

  Widget _buildDropdownField<T>({
    required T? value,
    required Color dropdownColor,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: dropdownColor,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF22252A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
      items: items,
      validator: validator,
      onChanged: onChanged,
    );
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
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
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
            onPressed: _isSaving || _isLoadingRole ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: const Color(0xFF0C0E12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0C0E12)),
                  )
                : Text(
                    widget.admin == null ? 'REGISTRAR' : 'GUARDAR CAMBIOS',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      child: _isLoadingRole
          ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFF00F0FF))))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                              validator: (val) => val == null || val.isEmpty ? 'El nombre es obligatorio' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StyledTextField(
                              controller: _apellidoCtrl,
                              hintText: 'Apellido',
                              icon: Icons.person_outline,
                              validator: (val) => val == null || val.isEmpty ? 'El apellido es obligatorio' : null,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      StyledTextField(
                        controller: _nombreCtrl,
                        hintText: 'Nombre',
                        icon: Icons.person,
                        validator: (val) => val == null || val.isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                      const SizedBox(height: 12),
                      StyledTextField(
                        controller: _apellidoCtrl,
                        hintText: 'Apellido',
                        icon: Icons.person_outline,
                        validator: (val) => val == null || val.isEmpty ? 'El apellido es obligatorio' : null,
                      ),
                    ],
                    const SizedBox(height: 12),

                    if (isTablet)
                      Row(
                        children: [
                          Expanded(
                            child: StyledTextField(
                              controller: _celularCtrl,
                              hintText: 'Celular (ej. +591 70000000)',
                              icon: Icons.phone_android_outlined,
                              validator: (val) => val == null || val.isEmpty ? 'El celular es obligatorio' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StyledTextField(
                              controller: _dniCtrl,
                              hintText: 'Cédula / DNI',
                              icon: Icons.badge_outlined,
                              validator: (val) => val == null || val.isEmpty ? 'La cédula es obligatoria' : null,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      StyledTextField(
                        controller: _celularCtrl,
                        hintText: 'Celular (ej. +591 70000000)',
                        icon: Icons.phone_android_outlined,
                        validator: (val) => val == null || val.isEmpty ? 'El celular es obligatorio' : null,
                      ),
                      const SizedBox(height: 12),
                      StyledTextField(
                        controller: _dniCtrl,
                        hintText: 'Cédula / DNI',
                        icon: Icons.badge_outlined,
                        validator: (val) => val == null || val.isEmpty ? 'La cédula es obligatoria' : null,
                      ),
                    ],
                    const SizedBox(height: 12),

                    if (isTablet)
                      Row(
                        children: [
                          Expanded(
                            child: StyledTextField(
                              controller: _nacionalidadCtrl,
                              hintText: 'Nacionalidad',
                              icon: Icons.flag_outlined,
                              validator: (val) => val == null || val.isEmpty ? 'La nacionalidad es obligatoria' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdownField<String>(
                              value: _selectedGender,
                              dropdownColor: const Color(0xFF1E2024),
                              hint: 'Género',
                              items: const [
                                DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                                DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
                                DropdownMenuItem(value: 'PREFIERO_NO_DECIRLO', child: Text('Prefiero no decirlo')),
                              ],
                              validator: (val) => val == null || val.isEmpty ? 'El género es obligatorio' : null,
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedGender = val);
                              },
                            ),
                          ),
                        ],
                      )
                    else ...[
                      StyledTextField(
                        controller: _nacionalidadCtrl,
                        hintText: 'Nacionalidad',
                        icon: Icons.flag_outlined,
                        validator: (val) => val == null || val.isEmpty ? 'La nacionalidad es obligatoria' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownField<String>(
                        value: _selectedGender,
                        dropdownColor: const Color(0xFF1E2024),
                        hint: 'Género',
                        items: const [
                          DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                          DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
                          DropdownMenuItem(value: 'PREFIERO_NO_DECIRLO', child: Text('Prefiero no decirlo')),
                        ],
                        validator: (val) => val == null || val.isEmpty ? 'El género es obligatorio' : null,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGender = val);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),

                    StyledTextField(
                      controller: _direccionCtrl,
                      hintText: 'Dirección física (ej. Av. Siempre Viva 123)',
                      icon: Icons.home_outlined,
                      validator: (val) => val == null || val.isEmpty ? 'La dirección es obligatoria' : null,
                    ),
                    const SizedBox(height: 24),

                    Text('DATOS DE ACCESO', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), letterSpacing: 0.5)),
                    const SizedBox(height: 12),

                    StyledTextField(
                      controller: _usernameCtrl,
                      hintText: 'Nombre de usuario (ej: admin_sucre)',
                      icon: Icons.alternate_email,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'El usuario es obligatorio';
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
                          if (val == null || val.isEmpty) return 'La contraseña es obligatoria';
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
