import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../admin/providers/menu_admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../../../core/constants/api_constants.dart';

class PerfilPage extends ConsumerStatefulWidget {
  const PerfilPage({super.key});

  @override
  ConsumerState<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends ConsumerState<PerfilPage> {
  bool _isUploading = false;
  String? _localImagePath;

  // Password fields
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdatingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      // Vista previa local instantánea
      setState(() {
        _localImagePath = image.path;
        _isUploading = true;
      });

      // Subida en red a través de la carpeta usuarios
      final uploadNotifier = ref.read(menuAdminProvider.notifier);
      final String? fotoUrl = await uploadNotifier.uploadImage(image.path, 'usuarios');

      if (fotoUrl != null) {
        await ref.read(authProvider.notifier).updateProfile(fotoUrl: fotoUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _localImagePath = null; // Revertir vista previa
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al subir la foto de perfil'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _localImagePath = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _showChangePasswordBottomSheet(BuildContext context) async {
    // Clear fields before showing
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.of(context).viewInsets;
            final size = MediaQuery.of(context).size;
            final maxModalHeight = size.height * 0.85;

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
                          'Cambiar Contraseña',
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
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'CONTRASEÑA ACTUAL',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFB9CACB),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildStyledField(
                              controller: _currentPasswordController,
                              hintText: 'Escribe tu contraseña actual',
                              obscureText: _obscureCurrent,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.white54),
                                onPressed: () => setModalState(() => _obscureCurrent = !_obscureCurrent),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Por favor escribe tu clave actual';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

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
                            _buildStyledField(
                              controller: _newPasswordController,
                              hintText: 'Mínimo 6 caracteres',
                              obscureText: _obscureNew,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.white54),
                                onPressed: () => setModalState(() => _obscureNew = !_obscureNew),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Por favor escribe una nueva clave';
                                if (val.length < 6) return 'Debe tener al menos 6 caracteres';
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
                            _buildStyledField(
                              controller: _confirmPasswordController,
                              hintText: 'Repite tu nueva contraseña',
                              obscureText: _obscureConfirm,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.white54),
                                onPressed: () => setModalState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              validator: (val) {
                                if (val != _newPasswordController.text) return 'Las contraseñas no coinciden';
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
                      16 + MediaQuery.of(context).padding.bottom
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
                          onPressed: _isUpdatingPassword
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  
                                  setModalState(() {
                                    _isUpdatingPassword = true;
                                  });
                                  
                                  try {
                                    await ref.read(authProvider.notifier).updateProfile(
                                          password: _newPasswordController.text,
                                        );
                                    if (mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Contraseña actualizada con éxito'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  } finally {
                                    setModalState(() {
                                      _isUpdatingPassword = false;
                                    });
                                  }
                                },
                          child: _isUpdatingPassword
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : Text(
                                  'ACTUALIZAR',
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

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF22252A),
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                child: Icon(prefixIcon, color: Colors.white30, size: 16),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 16,
        ),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
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
      validator: validator,
    );
  }

  Color _getRoleColor(String roleName) {
    switch (roleName.toUpperCase()) {
      case 'ADMIN':
        return const Color(0xFF00F0FF); // Electric Cyan
      case 'BARMAN':
        return const Color(0xFFE040FB); // Violet
      case 'DAMA':
        return const Color(0xFFFF4081); // Rose / Pink
      default:
        return const Color(0xFF7C4DFF); // Deep Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final roleColor = _getRoleColor(user.rolNombre);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 12.0),
          // Interactive Avatar Stack
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: roleColor.withOpacity(0.4),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withOpacity(0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56.0,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    backgroundImage: _localImagePath != null
                        ? FileImage(File(_localImagePath!)) as ImageProvider
                        : (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                            ? NetworkImage(ApiConstants.resolveImageUrl(user.fotoUrl)!)
                            : null,
                    child: _localImagePath == null && (user.fotoUrl == null || user.fotoUrl!.isEmpty)
                        ? Text(
                            user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 38.0,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: roleColor,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: roleColor == const Color(0xFF00F0FF) ? Colors.black : Colors.white,
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            '${user.nombre} ${user.apellido}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: roleColor.withOpacity(0.3), width: 0.8),
            ),
            child: Text(
              user.rolNombre.toUpperCase(),
              style: TextStyle(
                color: roleColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          _buildTechnicalSection(
            title: 'Cuenta y Seguridad',
            accentColor: roleColor,
            children: [
              _buildTechnicalRow(
                icon: Icons.alternate_email,
                label: 'Nombre de Usuario',
                value: '@${user.username}',
                accentColor: roleColor,
              ),
              _buildTechnicalRow(
                icon: Icons.security_outlined,
                label: 'Rango de Acceso / Rol',
                value: user.rolNombre.toUpperCase(),
                accentColor: roleColor,
              ),
              _buildTechnicalRow(
                icon: Icons.apartment_outlined,
                label: 'Sucursal bar asignado',
                value: user.barId?.isNotEmpty == true ? (user.barId!.length > 8 ? user.barId!.substring(0, 8) : user.barId!) : 'Global / Principal',
                accentColor: roleColor,
                showDivider: false,
              ),
            ],
          ),

          _buildTechnicalSection(
            title: 'Datos Personales y de Contacto',
            accentColor: roleColor,
            children: [
              _buildTechnicalRow(
                icon: Icons.badge_outlined,
                label: 'DNI / Cédula de Identificación',
                value: user.identificacion?.isNotEmpty == true ? user.identificacion! : 'No registrado',
                accentColor: roleColor,
              ),
              _buildTechnicalRow(
                icon: Icons.phone_android,
                label: 'Celular / Teléfono',
                value: user.celular?.isNotEmpty == true ? user.celular! : 'No registrado',
                accentColor: roleColor,
              ),
              _buildTechnicalRow(
                icon: Icons.flag_outlined,
                label: 'Nacionalidad',
                value: user.nacionalidad?.isNotEmpty == true ? user.nacionalidad! : 'No registrado',
                accentColor: roleColor,
              ),
              _buildTechnicalRow(
                icon: Icons.wc_outlined,
                label: 'Género',
                value: user.genero == 'MASCULINO'
                    ? 'Masculino'
                    : user.genero == 'FEMENINO'
                        ? 'Femenino'
                        : 'Prefiero no decirlo',
                accentColor: roleColor,
              ),
              _buildTechnicalRow(
                icon: Icons.location_on_outlined,
                label: 'Dirección Domiciliaria',
                value: user.direccion?.isNotEmpty == true ? user.direccion! : 'No registrada',
                accentColor: roleColor,
                showDivider: false,
              ),
            ],
          ),

          const SizedBox(height: 12.0),

          // Outlined Button to Change Password via Bottom Sheet
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.lock_reset, color: Color(0xFF00F0FF)),
              label: const Text(
                'CAMBIAR CONTRASEÑA',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00F0FF), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _showChangePasswordBottomSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSection({
    required String title,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF16181C), // Deep steel background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.015),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalRow({
    required IconData icon,
    required String label,
    required String value,
    Color? accentColor,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (accentColor ?? const Color(0xFF00F0FF)).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: accentColor ?? const Color(0xFF00F0FF),
                  size: 16,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: Colors.white.withOpacity(0.03),
            height: 1,
            thickness: 1,
          ),
      ],
    );
  }
}
