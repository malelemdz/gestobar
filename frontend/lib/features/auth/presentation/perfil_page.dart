import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../admin/providers/menu_admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/styled_text_field.dart';
import '../../staff/presentation/widgets/technical_sheet_widgets.dart';

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

    final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

    Widget buildModalContent(BuildContext context, StateSetter setModalState, bool isDialog) {
      final viewInsets = MediaQuery.of(context).viewInsets;
      final size = MediaQuery.of(context).size;
      final maxModalHeight = size.height * (isDialog ? 0.8 : 0.85);

      return Container(
        constraints: BoxConstraints(
          maxHeight: maxModalHeight,
        ),
        margin: isDialog ? EdgeInsets.zero : EdgeInsets.only(bottom: viewInsets.bottom),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024), // Level 2 Modal
          borderRadius: isDialog
              ? BorderRadius.circular(24.0)
              : const BorderRadius.vertical(top: Radius.circular(24.0)),
          border: isDialog
              ? Border.all(color: Colors.white.withOpacity(0.06), width: 1.0)
              : Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
                ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            if (!isDialog)
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
                            StyledTextField(
                              controller: _currentPasswordController,
                              hintText: 'Escribe tu contraseña actual',
                              isPassword: _obscureCurrent,
                              icon: Icons.lock_outline,
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
                            StyledTextField(
                              controller: _newPasswordController,
                              hintText: 'Mínimo 6 caracteres',
                              isPassword: _obscureNew,
                              icon: Icons.lock_outline,
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
                            StyledTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Repite tu nueva contraseña',
                              isPassword: _obscureConfirm,
                              icon: Icons.lock_outline,
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
                      16 + (isDialog ? 0.0 : MediaQuery.of(context).padding.bottom)
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
    }

    if (isTabletLandscape) {
      await showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.85),
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return buildModalContent(context, setModalState, true);
                },
              ),
            ),
          );
        },
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return buildModalContent(context, setModalState, false);
            },
          );
        },
      );
    }
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

          TechnicalSection(
            title: 'Cuenta y Seguridad',
            accentColor: roleColor,
            children: [
              TechnicalRow(
                icon: Icons.alternate_email,
                label: 'Nombre de Usuario',
                value: '@${user.username}',
                accentColor: roleColor,
              ),
              TechnicalRow(
                icon: Icons.security_outlined,
                label: 'Rango de Acceso / Rol',
                value: user.rolNombre.toUpperCase(),
                accentColor: roleColor,
              ),
              TechnicalRow(
                icon: Icons.apartment_outlined,
                label: 'Sucursal bar asignado',
                value: user.barId?.isNotEmpty == true ? (user.barId!.length > 8 ? user.barId!.substring(0, 8) : user.barId!) : 'Global / Principal',
                accentColor: roleColor,
                showDivider: false,
              ),
            ],
          ),

          TechnicalSection(
            title: 'Datos Personales y de Contacto',
            accentColor: roleColor,
            children: [
              TechnicalRow(
                icon: Icons.badge_outlined,
                label: 'DNI / Cédula de Identificación',
                value: user.identificacion?.isNotEmpty == true ? user.identificacion! : 'No registrado',
                accentColor: roleColor,
              ),
              TechnicalRow(
                icon: Icons.phone_android,
                label: 'Celular / Teléfono',
                value: user.celular?.isNotEmpty == true ? user.celular! : 'No registrado',
                accentColor: roleColor,
              ),
              TechnicalRow(
                icon: Icons.flag_outlined,
                label: 'Nacionalidad',
                value: user.nacionalidad?.isNotEmpty == true ? user.nacionalidad! : 'No registrado',
                accentColor: roleColor,
              ),
              TechnicalRow(
                icon: Icons.wc_outlined,
                label: 'Género',
                value: user.genero == 'MASCULINO'
                    ? 'Masculino'
                    : user.genero == 'FEMENINO'
                        ? 'Femenino'
                        : 'Prefiero no decirlo',
                accentColor: roleColor,
              ),
              TechnicalRow(
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
}
