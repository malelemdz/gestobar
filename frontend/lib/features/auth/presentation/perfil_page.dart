import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../admin/providers/menu_admin_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/widgets/styled_text_field.dart';
import '../../staff/presentation/widgets/technical_sheet_widgets.dart';
import '../../../core/widgets/responsive_modal.dart';

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
          CustomToast.show(
            context,
            message: 'Foto de perfil actualizada correctamente',
            type: ToastType.success,
          );
        }
      } else {
        setState(() {
          _localImagePath = null; // Revertir vista previa
        });
        if (mounted) {
          CustomToast.show(
            context,
            message: 'Error al subir la foto de perfil',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      setState(() {
        _localImagePath = null;
      });
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Error: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }  Future<void> _showChangePasswordBottomSheet(BuildContext context) async {
    // Clear fields before showing
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

    Widget buildModalContent(BuildContext context, StateSetter setModalState, bool isDialog) {
      final Widget formBody = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CONTRASEÑA ACTUAL',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
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
                        CustomToast.show(
                          context,
                          message: 'Contraseña actualizada con éxito',
                          type: ToastType.success,
                        );
                      }
                    } catch (e) {
                      CustomToast.show(
                        context,
                        message: 'Error: ${e.toString()}',
                        type: ToastType.error,
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
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0c0e12),
                    ),
                  ),
          ),
        ],
      );

      return ResponsiveModalContainer(
        title: 'Cambiar Contraseña',
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

  Future<void> _showEditProfileBottomSheet(BuildContext context) async {
    final authState = ref.read(authProvider) as AuthAuthenticated;
    final user = authState.user;
    final roleColor = _getRoleColor(user.rolNombre);

    final editFormKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: user.nombre);
    final apellidoCtrl = TextEditingController(text: user.apellido);
    final usernameCtrl = TextEditingController(text: user.username);
    final identificacionCtrl = TextEditingController(text: user.identificacion);
    final celularCtrl = TextEditingController(text: user.celular);
    final nacionalidadCtrl = TextEditingController(text: user.nacionalidad);
    final direccionCtrl = TextEditingController(text: user.direccion);

    String selectedGenero = user.genero ?? 'PREFIERO_NO_DECIRLO';
    String? tempFotoUrl = user.fotoUrl;
    bool modalUploading = false;
    String? modalLocalPath;
    bool isSaving = false;

    final bool isTabletLandscape = MediaQuery.of(context).size.width >= 720;

    Widget buildModalContent(BuildContext context, StateSetter setModalState, bool isDialog) {
      Future<void> modalPickImage() async {
        try {
          final picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );

          if (image == null) return;

          setModalState(() {
            modalLocalPath = image.path;
            modalUploading = true;
          });

          final uploadNotifier = ref.read(menuAdminProvider.notifier);
          final String? uploadedUrl = await uploadNotifier.uploadImage(image.path, 'usuarios');

          if (uploadedUrl != null) {
            setModalState(() {
              tempFotoUrl = uploadedUrl;
            });
          } else {
            setModalState(() {
              modalLocalPath = null;
            });
            if (mounted) {
              CustomToast.show(context, message: 'Error al subir la foto', type: ToastType.error);
            }
          }
        } catch (e) {
          setModalState(() {
            modalLocalPath = null;
          });
          if (mounted) {
            CustomToast.show(context, message: 'Error: $e', type: ToastType.error);
          }
        } finally {
          setModalState(() {
            modalUploading = false;
          });
        }
      }

      final Widget formBody = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: editFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                      ),
                      child: CircleAvatar(
                        radius: 46.0,
                        backgroundColor: Colors.white10,
                        backgroundImage: modalLocalPath != null
                            ? FileImage(File(modalLocalPath!)) as ImageProvider
                            : (tempFotoUrl != null && tempFotoUrl!.isNotEmpty)
                                ? NetworkImage(ApiConstants.resolveImageUrl(tempFotoUrl)!)
                                : null,
                        child: modalLocalPath == null && (tempFotoUrl == null || tempFotoUrl!.isEmpty)
                            ? Text(
                                nombreCtrl.text.isNotEmpty ? nombreCtrl.text[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (modalUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
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
                          onTap: modalUploading ? null : modalPickImage,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: roleColor == const Color(0xFF00F0FF) ? Colors.black : Colors.white,
                              size: 16.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'NOMBRE',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              StyledTextField(
                controller: nombreCtrl,
                hintText: 'Tu nombre',
                icon: Icons.person_outline,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'El nombre es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Text(
                'APELLIDO',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              StyledTextField(
                controller: apellidoCtrl,
                hintText: 'Tu apellido',
                icon: Icons.person_outline,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'El apellido es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Text(
                'NOMBRE DE USUARIO',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              StyledTextField(
                controller: usernameCtrl,
                hintText: 'Tu nombre de usuario',
                icon: Icons.alternate_email,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'El nombre de usuario es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Text(
                'IDENTIFICACIÓN / CÉDULA',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              StyledTextField(
                controller: identificacionCtrl,
                hintText: 'Identificación',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 16),

              Text(
                'CELULAR / TELÉFONO',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              StyledTextField(
                controller: celularCtrl,
                hintText: 'Número de celular',
                icon: Icons.phone_android,
              ),
              const SizedBox(height: 16),

              Text(
                'NACIONALIDAD',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              StyledTextField(
                controller: nacionalidadCtrl,
                hintText: 'Nacionalidad',
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 16),

              Text(
                'GÉNERO',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedGenero,
                dropdownColor: const Color(0xFF22252A),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12.0, right: 8.0),
                    child: Icon(Icons.wc_outlined, color: Colors.white30, size: 16),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 16,
                  ),
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
                ),
                items: const [
                  DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                  DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
                  DropdownMenuItem(value: 'PREFIERO_NO_DECIRLO', child: Text('Prefiero no decirlo')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() {
                      selectedGenero = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              Text(
                'DIRECCIÓN DOMICILIARIA',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9CACB),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              StyledTextField(
                controller: direccionCtrl,
                hintText: 'Dirección',
                icon: Icons.location_on_outlined,
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
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
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
            onPressed: isSaving || modalUploading
                ? null
                : () async {
                    if (!editFormKey.currentState!.validate()) return;

                    setModalState(() {
                      isSaving = true;
                    });

                    try {
                      await ref.read(authProvider.notifier).updateProfile(
                            nombre: nombreCtrl.text,
                            apellido: apellidoCtrl.text,
                            username: usernameCtrl.text,
                            identificacion: identificacionCtrl.text,
                            celular: celularCtrl.text,
                            nacionalidad: nacionalidadCtrl.text,
                            direccion: direccionCtrl.text,
                            genero: selectedGenero,
                            fotoUrl: tempFotoUrl,
                          );
                      if (mounted) {
                        Navigator.pop(context);
                        CustomToast.show(
                          context,
                          message: 'Perfil actualizado correctamente',
                          type: ToastType.success,
                        );
                      }
                    } catch (e) {
                      CustomToast.show(
                        context,
                        message: 'Error: ${e.toString()}',
                        type: ToastType.error,
                      );
                    } finally {
                      setModalState(() {
                        isSaving = false;
                      });
                    }
                  },
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : Text(
                    'GUARDAR',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0c0e12),
                    ),
                  ),
          ),
        ],
      );

      return ResponsiveModalContainer(
        title: 'Editar Perfil',
        isDialog: isDialog,
        footer: footer,
        child: formBody,
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
    final bool isTablet = MediaQuery.of(context).size.width >= 720;

    Widget buildAvatarAndName({required bool showChangePassword}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                if (user.rolNombre.toUpperCase() != 'SUPERADMIN')
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
            textAlign: TextAlign.center,
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
              ),
            ),
          ),
          if (showChangePassword) ...[
            const SizedBox(height: 32.0),
            if (user.rolNombre.toUpperCase() == 'SUPERADMIN') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  label: const Text(
                    'EDITAR CUENTA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showEditProfileBottomSheet(context),
                ),
              ),
              const SizedBox(height: 12.0),
            ],
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
                    fontSize: 12,
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
        ],
      );
    }

    final List<Widget> rightColumnChildren = [
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
            value: user.barId?.isNotEmpty == true
                ? (user.barId!.length > 8 ? user.barId!.substring(0, 8) : user.barId!)
                : 'Global / Principal',
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
    ];

    if (isTablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: User profile header summary card
          Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withOpacity(0.02),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: buildAvatarAndName(showChangePassword: true),
              ),
            ),
          ),
          // Standardized 1px vertical divider
          Container(
            width: 1,
            color: Colors.white.withOpacity(0.04),
          ),
          // Right side: Profile data sheets
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rightColumnChildren,
              ),
            ),
          ),
        ],
      );
    }

    // Mobile Layout
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 12.0),
          buildAvatarAndName(showChangePassword: false),
          const SizedBox(height: 24.0),
          ...rightColumnChildren,
          const SizedBox(height: 12.0),
          if (user.rolNombre.toUpperCase() == 'SUPERADMIN') ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.black),
                label: const Text(
                  'EDITAR CUENTA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F0FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showEditProfileBottomSheet(context),
              ),
            ),
            const SizedBox(height: 12.0),
          ],
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
