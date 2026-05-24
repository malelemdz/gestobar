import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/premium_fab.dart';
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
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabController.index;
        });
      }
    });
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
      floatingActionButton: _activeTab == 0
          ? PremiumFAB(
              label: 'Nuevo usuario',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => _showAddEditStaffDialog(context, null),
            )
          : PremiumFAB(
              label: 'Nuevo rol',
              icon: Icons.add_moderator_outlined,
              onPressed: () => _showAddEditRoleDialog(context, null),
            ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background.withOpacity(0.4),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search & Custom Tab bar Selector (Starts directly with search, no titles!)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _activeTab == 0
                            ? 'Buscar por nombre, apellido o usuario...'
                            : 'Buscar roles...',
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
                    const SizedBox(height: 12),
                    // Custom Tab switcher matching Caja's premium style
                    Container(
                      height: 46,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A1E),
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: Colors.white.withOpacity(0.03)),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(0, 'USUARIOS', Icons.people_outline),
                          _buildTabButton(1, 'ROLES', Icons.security_outlined),
                        ],
                      ),
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 420,
                            mainAxisExtent: 148,
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
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                          radius: 26,
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
                                    fontSize: 18,
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
                            child: const Icon(Icons.block, color: Colors.redAccent, size: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Neon switch for status
                  Row(
                    children: [
                      Transform.scale(
                        scale: 0.65,
                        child: Switch(
                          value: user.estado,
                          activeColor: const Color(0xFF00F0FF),
                          activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.3),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.white10,
                          onChanged: (val) async {
                            final confirm = await _showStatusConfirmationBottomSheet(
                              context: context,
                              user: user,
                              targetState: val,
                            );
                            if (confirm == true) {
                              ref.read(staffListProvider.notifier).toggleStaffStatus(user.id, val);
                            }
                          },
                        ),
                      ),
                      Text(
                        user.estado ? 'ACTIVO' : 'INAC',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: user.estado ? const Color(0xFF00F0FF) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
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
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${user.username}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Role Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: roleColor.withOpacity(0.3), width: 0.8),
                          ),
                          child: Text(
                            user.rolNombre.toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Contact Info
                    Row(
                      children: [
                        Icon(Icons.phone, size: 10, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          user.celular?.isNotEmpty == true ? user.celular! : 'Sin celular',
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.badge, size: 10, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        const SizedBox(width: 4),
                        Text(
                          user.identificacion?.isNotEmpty == true ? user.identificacion! : 'DNI No reg.',
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Action Buttons (Row)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.vpn_key_outlined, size: 15, color: Colors.amber),
                          tooltip: 'Cambiar Contraseña',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showResetPasswordBottomSheet(context, user),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 15, color: Colors.blueAccent),
                          tooltip: 'Editar',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showAddEditStaffDialog(context, user),
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
  // 💴 BOTÓN DE PESTAÑA PERSONALIZADO
  // =========================================================================
  Widget _buildTabButton(int index, String label, IconData icon) {
    final bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {
            _activeTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF00F0FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF00F0FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? Colors.black : Colors.white30,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isActive ? Colors.black : Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // MODALS & BOTTOM SHEETS
  // =========================================================================

  Future<void> _showAddEditStaffDialog(BuildContext context, UserModel? user) async {
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
            final viewInsets = MediaQuery.of(context).viewInsets;
            final size = MediaQuery.of(context).size;
            final maxModalHeight = size.height * 0.9;

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
                          isEdit ? 'Editar Personal' : 'Nuevo Empleado',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NOMBRE',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildStyledField(
                                      controller: nameController,
                                      hintText: 'Ej. Juan',
                                      icon: Icons.person_outline,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'APELLIDO',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildStyledField(
                                      controller: lastNameController,
                                      hintText: 'Ej. Pérez',
                                      icon: Icons.person_outline,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (!isEdit)
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NOMBRE DE USUARIO',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFB9CACB),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildStyledField(
                                        controller: usernameController,
                                        hintText: 'Ej. juan.perez',
                                        icon: Icons.alternate_email,
                                        enabled: true,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CONTRASEÑA',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFB9CACB),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildStyledField(
                                        controller: passwordController,
                                        hintText: 'Mínimo 6 caracteres',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOMBRE DE USUARIO',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFB9CACB),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildStyledField(
                                  controller: usernameController,
                                  hintText: 'Ej. juan.perez',
                                  icon: Icons.alternate_email,
                                  enabled: false,
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CÉDULA / DNI',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildStyledField(
                                      controller: dniController,
                                      hintText: 'Ej. 1234567',
                                      icon: Icons.badge_outlined,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CELULAR',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildStyledField(
                                      controller: phoneController,
                                      hintText: 'Ej. +591 70000000',
                                      icon: Icons.phone_android_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NACIONALIDAD',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildStyledField(
                                      controller: countryController,
                                      hintText: 'Ej. Bolivia',
                                      icon: Icons.flag_outlined,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DIRECCIÓN',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildStyledField(
                                      controller: addressController,
                                      hintText: 'Ej. Av. Siempre Viva 123',
                                      icon: Icons.home_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              // Gender
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GÉNERO',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C0E12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: DropdownButtonFormField<String>(
                                        value: selectedGender,
                                        dropdownColor: const Color(0xFF1E2024),
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        hint: const Text('Género', style: TextStyle(color: Colors.white30, fontSize: 14)),
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
                                      'ROL',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFFB9CACB),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C0E12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: DropdownButtonFormField<String>(
                                        value: selectedRoleId,
                                        dropdownColor: const Color(0xFF1E2024),
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        hint: const Text('Seleccionar Rol', style: TextStyle(color: Colors.white30, fontSize: 14)),
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
                                        validator: (val) => val == null ? 'Requerido' : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        // Validation
                                        if (nameController.text.trim().isEmpty ||
                                            lastNameController.text.trim().isEmpty ||
                                            usernameController.text.trim().isEmpty ||
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

                                          if (!isEdit && passwordController.text.isNotEmpty) {
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
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                      )
                                    : Text(
                                        isEdit ? 'GUARDAR CAMBIOS' : 'REGISTRAR EMPLEADO',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0c0e12),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
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

  Future<void> _showAddEditRoleDialog(BuildContext context, RoleModel? role) async {
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
            final viewInsets = MediaQuery.of(context).viewInsets;
            final size = MediaQuery.of(context).size;
            final maxModalHeight = size.height * 0.8;

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
                          isEdit ? 'Editar Rol' : 'Nuevo Rol Personalizado',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'NOMBRE DEL ROL',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9CACB),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildStyledField(
                            controller: nameController,
                            hintText: 'Ej. Ayudante de Barra',
                            icon: Icons.security,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'ASIGNAR PERMISOS DE ACCESO',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFB9CACB),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // List of permissions
                          Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C0E12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: permissionsAsync.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                                ),
                              ),
                              error: (err, _) => Center(
                                child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                              ),
                              data: (permissions) {
                                if (permissions.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No hay permisos disponibles',
                                      style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                                    ),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: permissions.length,
                                  itemBuilder: (context, index) {
                                    final perm = permissions[index];
                                    final isChecked = selectedPermissionIds.contains(perm.id);

                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        unselectedWidgetColor: Colors.white24,
                                      ),
                                      child: CheckboxListTile(
                                        title: Text(
                                          perm.nombre,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        value: isChecked,
                                        activeColor: const Color(0xFF00F0FF),
                                        checkColor: Colors.black,
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
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Actions
                          Row(
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                      )
                                    : Text(
                                        isEdit ? 'GUARDAR ROL' : 'CREAR ROL',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0c0e12),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
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

  Future<void> _showResetPasswordBottomSheet(BuildContext context, UserModel user) async {
    final passwordController = TextEditingController();
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.of(context).viewInsets;
            final size = MediaQuery.of(context).size;
            final maxModalHeight = size.height * 0.7;

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
                          'Restablecer Contraseña',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
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
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildStyledField(
                            controller: passwordController,
                            hintText: 'Mínimo 6 caracteres',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 32),

                          // Actions
                          Row(
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (passwordController.text.trim().isEmpty) {
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

                                        if (success && mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Contraseña restablecida con éxito'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          setModalState(() {
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
                          ),
                        ],
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

  Future<void> _showDeleteRoleConfirmation(BuildContext context, RoleModel role) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2024),
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

  Future<bool?> _showStatusConfirmationBottomSheet({
    required BuildContext context,
    required UserModel user,
    required bool targetState,
  }) {
    final confirmColor = targetState ? const Color(0xFF00F0FF) : Colors.redAccent;
    final title = targetState ? '¿HABILITAR EMPLEADO?' : '¿DESHABILITAR EMPLEADO?';
    final description = targetState
        ? '¿Estás seguro de que deseas habilitar a ${user.nombre} ${user.apellido}? El usuario podrá volver a ingresar al sistema y realizar todas sus funciones asignadas.'
        : '¿Estás seguro de que deseas deshabilitar a ${user.nombre} ${user.apellido}? El usuario ya no podrá iniciar sesión y se bloquearán sus operaciones de inmediato.';
    final confirmText = targetState ? 'Habilitar' : 'Deshabilitar';
    final icon = targetState ? Icons.check_circle_outline : Icons.block_outlined;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1E2024),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: confirmColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: confirmColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: targetState ? const Color(0xFF0C0E12) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        confirmText,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool isPassword = false,
    bool enabled = true,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        obscureText: isPassword,
        enabled: enabled,
        style: GoogleFonts.inter(
          color: enabled ? Colors.white : Colors.white54,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.white30, size: 18) : null,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        validator: validator,
      ),
    );
  }
}
