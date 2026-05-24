import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../admin/providers/staff_provider.dart';
import '../../admin/data/models/role_model.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/api_constants.dart';

class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});

  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends ConsumerState<StaffPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
        return const Color(0xFF7C4DFF); // Deep Purple for custom roles
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staffState = ref.watch(staffListProvider);
    final rolesState = ref.watch(rolesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background.withOpacity(0.4),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Glassmorphic Header & TabBar
              Container(
                padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.08),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ADMINISTRACIÓN DE PERSONAL',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gestiona tu equipo, roles dinámicos y permisos',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                        // Add buttons inside header depending on tab
                        AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, _) {
                            if (_tabController.index == 0) {
                              return ElevatedButton.icon(
                                onPressed: () => _showAddEditStaffDialog(context, null),
                                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                                label: const Text('NUEVO USUARIO'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00F0FF),
                                  foregroundColor: Colors.black,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            } else {
                              return ElevatedButton.icon(
                                onPressed: () => _showAddEditRoleDialog(context, null),
                                icon: const Icon(Icons.add_moderator_outlined, size: 18),
                                label: const Text('NUEVO ROL'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE040FB),
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar for Staff Tab
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        if (_tabController.index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre, apellido o usuario...',
                                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18, color: Colors.white),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: theme.colorScheme.onSurface.withOpacity(0.03),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.0),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF00F0FF),
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                      indicatorColor: const Color(0xFF00F0FF),
                      indicatorWeight: 3.0,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      tabs: const [
                        Tab(text: 'USUARIOS'),
                        Tab(text: 'ROLES'),
                      ],
                    ),
                  ],
                ),
              ),

              // TabBarViews
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // PERSONAL TAB
                    staffState.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error al cargar el personal: ${err.toString()}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (users) {
                        final filteredUsers = users.where((u) {
                          if (_searchQuery.isEmpty) return true;
                          final q = _searchQuery.toLowerCase();
                          return u.nombre.toLowerCase().contains(q) ||
                              u.apellido.toLowerCase().contains(q) ||
                              u.username.toLowerCase().contains(q);
                        }).toList();

                        if (filteredUsers.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'No se encontraron empleados',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 180,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return _buildStaffBentoCard(context, user);
                          },
                        );
                      },
                    ),

                    // ROLES TAB
                    rolesState.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE040FB)),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error al cargar roles: ${err.toString()}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (roles) {
                        if (roles.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.security, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay roles registrados',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: roles.length,
                          itemBuilder: (context, index) {
                            final role = roles[index];
                            return _buildRoleListTile(context, role);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffBentoCard(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final roleColor = _getRoleColor(user.rolNombre);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.estado
              ? roleColor.withOpacity(0.15)
              : theme.colorScheme.onSurface.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: user.estado
            ? [
                BoxShadow(
                  color: roleColor.withOpacity(0.03),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Avatar and switch
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: user.estado ? roleColor.withOpacity(0.4) : Colors.grey.withOpacity(0.3),
                            width: 2.0,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.black26,
                          backgroundImage: (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                              ? NetworkImage(ApiConstants.resolveImageUrl(user.fotoUrl)!)
                              : null,
                          child: (user.fotoUrl == null || user.fotoUrl!.isEmpty)
                              ? Text(
                                  user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                                  style: TextStyle(
                                    color: user.estado ? roleColor : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (!user.estado)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.block, color: Colors.redAccent, size: 24),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Neon switch for status
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: user.estado,
                          activeColor: const Color(0xFF00F0FF),
                          activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.3),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.white10,
                          onChanged: (val) {
                            ref.read(staffListProvider.notifier).toggleStaffStatus(user.id, val);
                          },
                        ),
                      ),
                      Text(
                        user.estado ? 'ACTIVO' : 'INAC',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: user.estado ? const Color(0xFF00F0FF) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Column 2: Text details and actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.nombre} ${user.apellido}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${user.username}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Role Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: roleColor.withOpacity(0.3), width: 0.8),
                          ),
                          child: Text(
                            user.rolNombre.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Contact Info
                    Row(
                      children: [
                        Icon(Icons.phone, size: 12, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          user.celular?.isNotEmpty == true ? user.celular! : 'Sin celular',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 12, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          user.identificacion?.isNotEmpty == true ? user.identificacion! : 'DNI No reg.',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Action Buttons (Row)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.vpn_key_outlined, size: 16, color: Colors.amber),
                          tooltip: 'Cambiar Contraseña',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showResetPasswordDialog(context, user),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueAccent),
                          tooltip: 'Editar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showAddEditStaffDialog(context, user),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                          tooltip: 'Eliminar (Deshabilitar)',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showDeleteConfirmation(context, user),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleListTile(BuildContext context, RoleModel role) {
    final theme = Theme.of(context);
    final isGlobal = role.barId == null;
    final roleColor = _getRoleColor(role.nombre);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              role.nombre.toUpperCase(),
              style: TextStyle(
                color: roleColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isGlobal ? Colors.blue.withOpacity(0.1) : Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isGlobal ? Colors.blue.withOpacity(0.3) : Colors.purple.withOpacity(0.3),
                  width: 0.6,
                ),
              ),
              child: Text(
                isGlobal ? 'SISTEMA' : 'PROPIO',
                style: TextStyle(
                  color: isGlobal ? Colors.blue : Colors.purpleAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${role.permisos.length} permisos asignados',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 12),
        ),
        trailing: isGlobal
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
                    onPressed: () => _showAddEditRoleDialog(context, role),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    onPressed: () => _showDeleteRoleConfirmation(context, role),
                  ),
                ],
              ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: role.permisos.isEmpty
                    ? [
                        Text(
                          'Sin permisos asociados.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 12),
                        )
                      ]
                    : role.permisos.map((p) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white10, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 10, color: Color(0xFF00F0FF)),
                              const SizedBox(width: 4),
                              Text(
                                p.nombre,
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MODALS & DIALOGS
  // =========================================================================

  Future<void> _showAddEditStaffDialog(BuildContext context, UserModel? user) async {
    final theme = Theme.of(context);
    final bool isEdit = user != null;

    final nameController = TextEditingController(text: user?.nombre);
    final lastNameController = TextEditingController(text: user?.apellido);
    final usernameController = TextEditingController(text: user?.username);
    final passwordController = TextEditingController();
    final phoneController = TextEditingController(text: user?.celular);
    final dniController = TextEditingController(text: user?.identificacion);
    final countryController = TextEditingController(text: user?.nacionalidad ?? 'Bolivia');
    final addressController = TextEditingController(text: user?.direccion);

    String selectedGender = user?.genero ?? 'PREFIERO_NO_DECIRLO';
    String? selectedRoleId = user?.rolId;

    String? localImagePath;
    bool isSaving = false;

    // Get assignable roles
    final rolesList = ref.read(rolesListProvider).value ?? [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'EDITAR PERSONAL' : 'NUEVO EMPLEADO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),

                    // Avatar picker with zero latency
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF00F0FF), width: 1.5),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.black45,
                              backgroundImage: localImagePath != null
                                  ? FileImage(File(localImagePath!)) as ImageProvider
                                  : (user?.fotoUrl != null && user!.fotoUrl!.isNotEmpty)
                                      ? NetworkImage(ApiConstants.resolveImageUrl(user.fotoUrl)!)
                                      : null,
                              child: localImagePath == null && (user?.fotoUrl == null || user!.fotoUrl!.isEmpty)
                                  ? const Icon(Icons.person, size: 40, color: Colors.white38)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () async {
                                final picker = ImagePicker();
                                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                if (img != null) {
                                  setModalState(() {
                                    localImagePath = img.path;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00F0FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalTextField(
                            theme,
                            'Nombre',
                            nameController,
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModalTextField(
                            theme,
                            'Apellido',
                            lastNameController,
                            icon: Icons.person_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModalTextField(
                            theme,
                            'Nombre de Usuario',
                            usernameController,
                            icon: Icons.alternate_email,
                            enabled: !isEdit, // No editable al editar
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModalTextField(
                            theme,
                            isEdit ? 'Nueva Contraseña (Opcional)' : 'Contraseña',
                            passwordController,
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModalTextField(
                            theme,
                            'Cédula / DNI',
                            dniController,
                            icon: Icons.badge_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModalTextField(
                            theme,
                            'Celular',
                            phoneController,
                            icon: Icons.phone_android_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModalTextField(
                            theme,
                            'Nacionalidad',
                            countryController,
                            icon: Icons.flag_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildModalTextField(
                            theme,
                            'Dirección',
                            addressController,
                            icon: Icons.home_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dropdowns for Role & Gender
                    Row(
                      children: [
                        // Gender
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Género',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedGender,
                                    dropdownColor: const Color(0xFF0F162A),
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                                      DropdownMenuItem(value: 'FEMENINO', child: Text('Femenino')),
                                      DropdownMenuItem(value: 'PREFIERO_NO_DECIRLO', child: Text('Prefiero no decirlo')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() {
                                          selectedGender = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Role
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rol',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRoleId,
                                    hint: const Text('Seleccionar Rol', style: TextStyle(color: Colors.white30, fontSize: 14)),
                                    dropdownColor: const Color(0xFF0F162A),
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    isExpanded: true,
                                    items: rolesList.map((r) {
                                      return DropdownMenuItem(
                                        value: r.id,
                                        child: Text(r.nombre),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setModalState(() {
                                        selectedRoleId = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F0FF),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                // Validation
                                if (nameController.text.isEmpty ||
                                    lastNameController.text.isEmpty ||
                                    usernameController.text.isEmpty ||
                                    selectedRoleId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor completa todos los campos obligatorios'),
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                  );
                                  return;
                                }

                                if (!isEdit && passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Por favor ingresa una contraseña'),
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  isSaving = true;
                                });

                                try {
                                  String? remotePhotoUrl = user?.fotoUrl;

                                  // Upload image first if changed
                                  if (localImagePath != null) {
                                    remotePhotoUrl = await ref
                                        .read(staffListProvider.notifier)
                                        .uploadPhoto(localImagePath!);
                                  }

                                  final payload = {
                                    'nombre': nameController.text.trim(),
                                    'apellido': lastNameController.text.trim(),
                                    'username': usernameController.text.trim().toLowerCase(),
                                    'rol_id': selectedRoleId,
                                    'genero': selectedGender,
                                    'celular': phoneController.text.trim(),
                                    'identificacion': dniController.text.trim(),
                                    'nacionalidad': countryController.text.trim(),
                                    'direccion': addressController.text.trim(),
                                    if (remotePhotoUrl != null) 'foto_url': remotePhotoUrl,
                                  };

                                  if (passwordController.text.isNotEmpty) {
                                    payload['password'] = passwordController.text;
                                  }

                                  bool success;
                                  if (isEdit) {
                                    success = await ref
                                        .read(staffListProvider.notifier)
                                        .updateStaff(user.id, payload);
                                  } else {
                                    success = await ref
                                        .read(staffListProvider.notifier)
                                        .createStaff(payload);
                                  }

                                  if (success && mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isEdit
                                            ? 'Empleado actualizado con éxito'
                                            : 'Empleado registrado con éxito'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    setModalState(() {
                                      isSaving = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Error al guardar el empleado. Comprueba tus datos.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                                isEdit ? 'GUARDAR CAMBIOS' : 'REGISTRAR EMPLEADO',
                                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddEditRoleDialog(BuildContext context, RoleModel? role) async {
    final theme = Theme.of(context);
    final bool isEdit = role != null;

    final nameController = TextEditingController(text: role?.nombre);
    List<String> selectedPermissionIds = role?.permisos.map((p) => p.id).toList() ?? [];

    bool isSaving = false;

    // Load available permissions
    final permissionsAsync = ref.read(permissionsListProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'EDITAR ROL PERSONALIZADO' : 'NUEVO ROL PERSONALIZADO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  _buildModalTextField(
                    theme,
                    'Nombre del Rol (Ej: Ayudante de Barra)',
                    nameController,
                    icon: Icons.security,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Asignar Permisos de Acceso',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: permissionsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                      data: (permissions) {
                        return ListView.builder(
                          itemCount: permissions.length,
                          itemBuilder: (context, index) {
                            final perm = permissions[index];
                            final isChecked = selectedPermissionIds.contains(perm.id);

                            return CheckboxListTile(
                              title: Text(
                                perm.nombre,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              value: isChecked,
                              activeColor: const Color(0xFFE040FB),
                              checkColor: Colors.white,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedPermissionIds.add(perm.id);
                                  } else {
                                    selectedPermissionIds.remove(perm.id);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE040FB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Por favor escribe un nombre para el rol'),
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                              });

                              bool success;
                              if (isEdit) {
                                success = await ref
                                    .read(rolesListProvider.notifier)
                                    .updateRole(
                                      role.id,
                                      nameController.text.trim(),
                                      selectedPermissionIds,
                                    );
                              } else {
                                success = await ref
                                    .read(rolesListProvider.notifier)
                                    .createRole(
                                      nameController.text.trim(),
                                      selectedPermissionIds,
                                    );
                              }

                              if (success && mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isEdit
                                        ? 'Rol actualizado correctamente'
                                        : 'Rol personalizado creado con éxito'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                setModalState(() {
                                  isSaving = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error al guardar el rol personalizado'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEdit ? 'GUARDAR ROL' : 'CREAR ROL PERSONALIZADO',
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
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

  Future<void> _showResetPasswordDialog(BuildContext context, UserModel user) async {
    final theme = Theme.of(context);
    final passwordController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0F162A),
              title: Text('RESTABLECER CONTRASEÑA', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escribe una nueva contraseña para ${user.nombre}. El usuario deberá usar esta clave para ingresar en su siguiente inicio de sesión.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _buildModalTextField(
                    theme,
                    'Nueva Contraseña',
                    passwordController,
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (passwordController.text.trim().isEmpty) {
                            return;
                          }

                          setState(() {
                            isSaving = true;
                          });

                          final success = await ref
                              .read(staffListProvider.notifier)
                              .updateStaff(user.id, {
                            'password': passwordController.text.trim(),
                          });

                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contraseña restablecida con éxito'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            setState(() {
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
                  child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('RESTABLECER'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, UserModel user) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F162A),
          title: const Text('¿INHABILITAR EMPLEADO?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text(
            'El empleado ${user.nombre} será deshabilitado (Soft Delete). No podrá iniciar sesión ni acceder al sistema, pero su registro histórico se mantendrá intacto para auditoría y comisiones.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await ref.read(staffListProvider.notifier).deleteStaff(user.id);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Empleado inhabilitado con éxito'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('INHABILITAR'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteRoleConfirmation(BuildContext context, RoleModel role) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F162A),
          title: const Text('¿ELIMINAR ROL?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: Text(
            '¿Estás seguro de que deseas eliminar el rol "${role.nombre}"? Los usuarios que posean este rol deberán ser reasignados.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                final success = await ref.read(rolesListProvider.notifier).deleteRole(role.id);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rol eliminado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('ELIMINAR ROL'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModalTextField(
    ThemeData theme,
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: isPassword,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white54,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: Colors.white38, size: 18) : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}
