import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/premium_fab.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../admin/providers/staff_provider.dart';
import '../../auth/models/user_model.dart';
import '../../admin/data/models/role_model.dart';


import 'widgets/staff_bento_card.dart';
import 'widgets/role_list_tile.dart';
import 'dialogs/add_edit_staff_dialog.dart';
import 'dialogs/add_edit_role_dialog.dart';
import 'dialogs/reset_password_bottom_sheet.dart';
import 'dialogs/delete_role_confirmation_dialog.dart';
import 'dialogs/status_confirmation_bottom_sheet.dart';

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

  Widget _buildSearchField(ThemeData theme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: _activeTab == 0
              ? 'Buscar por nombre, apellido o usuario...'
              : 'Buscar roles...',
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00F0FF), size: 20),
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim();
          });
        },
      ),
    );
  }

  Widget _buildVerticalTabButton(int index, String label, IconData icon) {
    final bool isActive = _activeTab == index;
    return GestureDetector(
      onTap: () {
        _tabController.animateTo(index);
        setState(() {
          _activeTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 42,
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00F0FF) : const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(isActive ? 0.0 : 0.04)),
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
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.black : Colors.white30,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.black : Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab(ThemeData theme, AsyncValue<List<UserModel>> staffState) {
    return RefreshIndicator(
      color: const Color(0xFF00F0FF),
      backgroundColor: const Color(0xFF1E2024),
      onRefresh: () async {
        await ref.read(staffListProvider.notifier).loadStaff();
      },
      child: staffState.when(
        loading: () => GridView.builder(
          padding: MediaQuery.of(context).size.width >= 900
              ? const EdgeInsets.fromLTRB(0, 8, 0, 12)
              : const EdgeInsets.fromLTRB(16, 12, 16, 12),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 420,
            mainAxisExtent: MediaQuery.of(context).size.width >= 720 ? 78 : 84,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => ShimmerPlaceholder(
            width: double.infinity,
            height: MediaQuery.of(context).size.width >= 720 ? 78 : 84,
          ),
        ),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 250,
            child: Center(
              child: Text(
                'Error al cargar el personal: ${err.toString()}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
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
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 250,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No se encontraron usuarios',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: MediaQuery.of(context).size.width >= 900
                ? const EdgeInsets.fromLTRB(0, 8, 0, 12)
                : const EdgeInsets.fromLTRB(16, 12, 16, 12),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 420,
              mainAxisExtent: MediaQuery.of(context).size.width >= 720 ? 78 : 84,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return StaffBentoCard(
                user: user,
                onShowStatusConfirmation: (context, u, target) =>
                    showStatusConfirmationBottomSheet(
                  context: context,
                  user: u,
                  targetState: target,
                ),
                onShowResetPassword: (context, u) =>
                    showResetPasswordBottomSheet(
                  context: context,
                  ref: ref,
                  user: u,
                ),
                onShowAddEditStaff: (context, u) =>
                    showAddEditStaffDialog(
                  context: context,
                  ref: ref,
                  user: u,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRolesTab(ThemeData theme, AsyncValue<List<RoleModel>> rolesState) {
    return RefreshIndicator(
      color: const Color(0xFFE040FB),
      backgroundColor: const Color(0xFF1E2024),
      onRefresh: () async {
        await ref.read(rolesListProvider.notifier).loadRoles();
      },
      child: rolesState.when(
        loading: () => ListView.builder(
          padding: MediaQuery.of(context).size.width >= 900
              ? const EdgeInsets.fromLTRB(0, 8, 0, 12)
              : const EdgeInsets.fromLTRB(16, 12, 16, 12),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: ShimmerPlaceholder(
              width: double.infinity,
              height: 58,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 250,
            child: Center(
              child: Text(
                'Error al cargar roles: ${err.toString()}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
        data: (roles) {
          if (roles.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 250,
                child: Center(
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
                ),
              ),
            );
          }

          return ListView.builder(
            padding: MediaQuery.of(context).size.width >= 900
                ? const EdgeInsets.fromLTRB(0, 8, 0, 12)
                : const EdgeInsets.fromLTRB(16, 12, 16, 12),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return RoleListTile(
                role: role,
                roleColor: _getRoleColor(role.nombre),
                onShowAddEditRole: (context, r) =>
                    showAddEditRoleDialog(
                  context: context,
                  ref: ref,
                  role: r,
                ),
                onShowDeleteRoleConfirmation: (context, r) =>
                    showDeleteRoleConfirmationDialog(
                  context: context,
                  ref: ref,
                  role: r,
                ),
              );
            },
          );
        },
      ),
    );
  }

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
                style: GoogleFonts.poppins(
                  color: isActive ? Colors.black : Colors.white30,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              onPressed: () => showAddEditStaffDialog(context: context, ref: ref, user: null),
            )
          : PremiumFAB(
              label: 'Nuevo rol',
              icon: Icons.add_moderator_outlined,
              onPressed: () => showAddEditRoleDialog(context: context, ref: ref, role: null),
            ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background.withOpacity(0.4),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isTablet = constraints.maxWidth >= 900;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unified Header
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24.0 : 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSearchField(theme),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Bento Pane: Categories (320px)
                              Container(
                                width: 320,
                                padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'SECCIONES',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white30,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    _buildVerticalTabButton(0, 'PERSONAL / USUARIOS', Icons.people_outline),
                                    _buildVerticalTabButton(1, 'ROLES Y PERMISOS', Icons.security_outlined),
                                  ],
                                ),
                              ),
                              // Elegant vertical divider line
                              Container(
                                width: 1,
                                color: Colors.white.withOpacity(0.04),
                              ),
                              // Right Bento Pane: Tab Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 24, 12),
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildPersonalTab(theme, staffState),
                                      _buildRolesTab(theme, rolesState),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // Mobile Tab Button Selector
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Container(
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
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildPersonalTab(theme, staffState),
                                    _buildRolesTab(theme, rolesState),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
