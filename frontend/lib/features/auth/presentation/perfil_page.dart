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

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider) as AuthAuthenticated;
    final user = authState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 16.0),
          // Interactive Avatar Stack
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 54.0,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  backgroundImage: (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                      ? NetworkImage(ApiConstants.resolveImageUrl(user.fotoUrl)!)
                      : null,
                  child: (user.fotoUrl == null || user.fotoUrl!.isEmpty)
                      ? Text(
                          user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 36.0,
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
                      color: Colors.black.withOpacity(0.5),
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
                  color: const Color(0xFF00F0FF),
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF00363A),
                        size: 20.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            user.nombre,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4.0),
          Chip(
            label: Text(user.rolNombre.toUpperCase()),
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 40.0),
          _buildProfileItem(context, Icons.phone_android, 'Celular', (user.celular != null && user.celular!.isNotEmpty) ? user.celular! : 'No registrado'),
          _buildProfileItem(context, Icons.badge_outlined, 'DNI / Documento', 'No registrado'),
          _buildProfileItem(context, Icons.flag_outlined, 'País / Región', 'Bolivia'),
          const SizedBox(height: 32.0),
          OutlinedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Restablecer Contraseña'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Acción disponible en la siguiente fase de desarrollo.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 20.0),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
