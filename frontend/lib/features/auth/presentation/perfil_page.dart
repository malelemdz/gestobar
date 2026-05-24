import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
    final theme = Theme.of(context);
    
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
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F1D).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: Colors.white10, width: 1.0),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CAMBIAR CONTRASEÑA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Contraseña Actual',
                          labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18),
                            onPressed: () => setModalState(() => _obscureCurrent = !_obscureCurrent),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white10),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00F0FF)),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Por favor escribe tu clave actual';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                            onPressed: () => setModalState(() => _obscureNew = !_obscureNew),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white10),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00F0FF)),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Por favor escribe una nueva clave';
                          if (val.length < 6) return 'Debe tener al menos 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña',
                          labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                            onPressed: () => setModalState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white10),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00F0FF)),
                          ),
                        ),
                        validator: (val) {
                          if (val != _newPasswordController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F0FF),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                          icon: const Icon(Icons.save_outlined),
                          label: _isUpdatingPassword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Text(
                                  'ACTUALIZAR CONTRASEÑA',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

          // Bento Section 1: Read-Only Profile Details
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'DATOS DE PERFIL (SOLO LECTURA)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // 2x4 Grid of Details
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _buildBentoItem(context, Icons.alternate_email, 'Usuario', '@${user.username}'),
              _buildBentoItem(context, Icons.phone_android, 'Celular', user.celular?.isNotEmpty == true ? user.celular! : 'No registrado'),
              _buildBentoItem(context, Icons.badge_outlined, 'DNI / Identificación', user.identificacion?.isNotEmpty == true ? user.identificacion! : 'No registrado'),
              _buildBentoItem(context, Icons.flag_outlined, 'Nacionalidad', user.nacionalidad?.isNotEmpty == true ? user.nacionalidad! : 'Bolivia'),
              _buildBentoItem(context, Icons.wc_outlined, 'Género', user.genero == 'MASCULINO' ? 'Masculino' : user.genero == 'FEMENINO' ? 'Femenino' : 'Prefiero no decirlo'),
              _buildBentoItem(context, Icons.location_on_outlined, 'Dirección', user.direccion?.isNotEmpty == true ? user.direccion! : 'No registrada'),
              _buildBentoItem(context, Icons.apartment_outlined, 'Sucursal ID', user.barId?.isNotEmpty == true ? user.barId!.substring(0, 8) : 'Global'),
              _buildBentoItem(context, Icons.security_outlined, 'Rango Acceso', user.rolNombre),
            ],
          ),

          const SizedBox(height: 32.0),

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

  Widget _buildBentoItem(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.015),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.04),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4), size: 14.0),
              const SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 12.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
