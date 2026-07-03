import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gestobar/core/network/dio_client.dart';
import 'package:gestobar/core/widgets/custom_toast.dart';
import 'package:gestobar/core/widgets/premium_fab.dart';
import 'package:gestobar/core/widgets/responsive_modal.dart';
import 'package:gestobar/core/widgets/shimmer_placeholder.dart';
import 'package:gestobar/features/auth/models/user_model.dart';
import 'package:gestobar/features/admin/presentation/dialogs/add_edit_admin_dialog.dart';
import 'package:gestobar/features/admin/presentation/dialogs/reset_admin_password_dialog.dart';
import 'package:gestobar/features/staff/presentation/dialogs/status_confirmation_bottom_sheet.dart';
import 'package:dio/dio.dart';

// State container for Administrators view
class SuperAdminsState {
  final List<UserModel> admins;
  final Map<String, String> adminBarMap;
  final bool isLoading;

  SuperAdminsState({
    required this.admins,
    required this.adminBarMap,
    required this.isLoading,
  });

  SuperAdminsState copyWith({
    List<UserModel>? admins,
    Map<String, String>? adminBarMap,
    bool? isLoading,
  }) {
    return SuperAdminsState(
      admins: admins ?? this.admins,
      adminBarMap: adminBarMap ?? this.adminBarMap,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Notifier controlling API requests and local states
class SuperAdminsNotifier extends StateNotifier<SuperAdminsState> {
  final Dio _dio;

  SuperAdminsNotifier(this._dio)
      : super(SuperAdminsState(admins: [], adminBarMap: {}, isLoading: true)) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Fetch bars to build owner -> bar name mapping
      final barsRes = await _dio.get('/bars');
      final List<dynamic> bars = barsRes.data ?? [];
      final Map<String, String> mapping = {};
      for (var b in bars) {
        final ownerId = b['owner_id'];
        if (ownerId != null) {
          mapping[ownerId] = b['nombre'].toString();
        }
      }

      // 2. Fetch all users in system
      final usersRes = await _dio.get('/users');
      final List<dynamic> users = usersRes.data ?? [];
      
      // Filter only users with role ADMIN
      final List<UserModel> adminsList = users
          .where((u) {
            final rol = u['rol'];
            return rol != null && rol['nombre'].toString().toUpperCase() == 'ADMIN';
          })
          .map((u) => UserModel.fromJson(u))
          .toList();

      state = SuperAdminsState(
        admins: adminsList,
        adminBarMap: mapping,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint('Error loading admins: $e');
    }
  }

  Future<bool> toggleAdminStatus(String userId, bool active) async {
    // Optimistic UI toggle
    final previousState = state.admins;
    state = state.copyWith(
      admins: state.admins.map((a) => a.id == userId ? a.copyWith(estado: active) : a).toList(),
    );

    try {
      await _dio.patch('/users/$userId', data: {'estado': active});
      return true;
    } catch (e) {
      // Revert if API failed
      state = state.copyWith(admins: previousState);
      debugPrint('Error toggling admin status: $e');
      return false;
    }
  }
}

// Provider definition
final superAdminsProvider =
    StateNotifierProvider.autoDispose<SuperAdminsNotifier, SuperAdminsState>((ref) {
  final dio = ref.watch(dioProvider);
  return SuperAdminsNotifier(dio);
});

class SuperAdminsPage extends ConsumerStatefulWidget {
  const SuperAdminsPage({super.key});

  @override
  ConsumerState<SuperAdminsPage> createState() => _SuperAdminsPageState();
}

class _SuperAdminsPageState extends ConsumerState<SuperAdminsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'TODOS'; // 'TODOS', 'ACTIVOS', 'INACTIVOS'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Row(
      children: [
        _buildFilterChip('TODOS', 'Todos', theme, isFirst: true),
        _buildFilterChip('ACTIVOS', 'Activos', theme),
        _buildFilterChip('INACTIVOS', 'Inactivos', theme, isLast: true),
      ],
    );
  }

  Widget _buildFilterChip(String filterCode, String label, ThemeData theme, {bool isFirst = false, bool isLast = false}) {
    final bool isActive = _statusFilter == filterCode;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          left: isFirst ? 0.0 : 4.0,
          right: isLast ? 0.0 : 4.0,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _statusFilter = filterCode;
            });
          },
          borderRadius: BorderRadius.circular(100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 38,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF00F0FF).withOpacity(0.15) : const Color(0xFF22252A),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isActive ? const Color(0xFF00F0FF).withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: isActive ? const Color(0xFF00F0FF) : Colors.white54,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 720;
    final state = ref.watch(superAdminsProvider);

    // Apply search and status filters locally
    final filteredAdmins = state.admins.where((admin) {
      final query = _searchQuery.toLowerCase();
      final fullName = '${admin.nombre} ${admin.apellido}'.toLowerCase();
      final username = admin.username.toLowerCase();
      
      final matchesSearch = fullName.contains(query) || username.contains(query);
      if (!matchesSearch) return false;

      if (_statusFilter == 'ACTIVOS') {
        return admin.estado == true;
      } else if (_statusFilter == 'INACTIVOS') {
        return admin.estado == false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: state.isLoading
          ? null
          : PremiumFAB(
              label: 'Nuevo admin',
              icon: Icons.add,
              onPressed: () {
                showResponsiveDialog(
                  context: context,
                  maxWidth: 550,
                  child: AddEditAdminDialog(
                    onSaved: () {
                      ref.read(superAdminsProvider.notifier).loadData();
                    },
                  ),
                );
              },
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top search bar block (styled like sucursales screen)
                Container(
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
                    controller: _searchCtrl,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF00F0FF), size: 20),
                      hintText: 'Buscar administradores por nombre o usuario...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.white),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  ),
                ),
                const SizedBox(height: 12.0),

                // Filter Chips block (spans full width of screen)
                _buildFilterChips(theme),
                const SizedBox(height: 12.0),

                // Content List block
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFF00F0FF),
                    backgroundColor: const Color(0xFF1E2024),
                    onRefresh: () async {
                      await ref.read(superAdminsProvider.notifier).loadData();
                    },
                    child: state.isLoading
                        ? ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: 5,
                            itemBuilder: (context, index) => const Padding(
                              padding: EdgeInsets.only(bottom: 12.0),
                              child: ShimmerPlaceholder(
                                width: double.infinity,
                                height: 70,
                                borderRadius: BorderRadius.all(Radius.circular(16)),
                              ),
                            ),
                          )
                        : filteredAdmins.isEmpty
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height - 250,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.admin_panel_settings_outlined,
                                          size: 48,
                                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No se encontraron administradores',
                                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                padding: EdgeInsets.zero,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400,
                                  mainAxisExtent: isTablet ? 78 : 84,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: filteredAdmins.length,
                                itemBuilder: (context, index) {
                              final admin = filteredAdmins[index];
                              final assignedBar = state.adminBarMap[admin.id] ?? 'Sin asignar';
                              final accentColor =
                                  admin.estado ? const Color(0xFF00F0FF) : Colors.redAccent;

                              return Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: accentColor.withOpacity(0.15),
                                    width: 1.2,
                                  ),
                                  boxShadow: admin.estado
                                      ? [
                                          BoxShadow(
                                            color: accentColor.withOpacity(0.03),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Col 1: Initials avatar
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.black26,
                                        child: Text(
                                          admin.nombre.isNotEmpty
                                              ? admin.nombre[0].toUpperCase()
                                              : 'A',
                                          style: TextStyle(
                                            color: accentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // Col 2: Profile info (name, username, bar name)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${admin.nombre} ${admin.apellido}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '@${admin.username.toLowerCase()} • $assignedBar',
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurfaceVariant
                                                    .withOpacity(0.7),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Col 3: Actions in single horizontal line
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 1. Password Reset Button
                                          Tooltip(
                                            message: 'Restablecer Contraseña',
                                            child: InkWell(
                                              onTap: () {
                                                showResponsiveDialog(
                                                  context: context,
                                                  maxWidth: 500,
                                                  child: ResetAdminPasswordDialog(
                                                    admin: admin,
                                                    onSaved: () {},
                                                  ),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(6),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Icon(
                                                  Icons.vpn_key_outlined,
                                                  size: 16,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),

                                          // 2. Edit Profile Button
                                          Tooltip(
                                            message: 'Editar Administrador',
                                            child: InkWell(
                                              onTap: () {
                                                showResponsiveDialog(
                                                  context: context,
                                                  maxWidth: 550,
                                                  child: AddEditAdminDialog(
                                                    admin: admin,
                                                    onSaved: () {
                                                      ref.read(superAdminsProvider.notifier).loadData();
                                                    },
                                                  ),
                                                );
                                              },
                                              borderRadius: BorderRadius.circular(6),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6.0),
                                                child: Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
                                                  color: Colors.blueAccent,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),

                                          // 3. Status Toggle Switch
                                          SizedBox(
                                            height: 24,
                                            width: 38,
                                            child: Transform.scale(
                                              scale: 0.65,
                                              child: Switch(
                                                value: admin.estado,
                                                activeColor: const Color(0xFF00F0FF),
                                                activeTrackColor: const Color(0xFF00F0FF).withOpacity(0.3),
                                                inactiveThumbColor: Colors.grey,
                                                inactiveTrackColor: Colors.white10,
                                                onChanged: (val) async {
                                                  final confirm =
                                                      await showStatusConfirmationBottomSheet(
                                                    context: context,
                                                    user: admin,
                                                    targetState: val,
                                                  );
                                                  if (confirm == true) {
                                                    final success = await ref
                                                        .read(superAdminsProvider.notifier)
                                                        .toggleAdminStatus(admin.id, val);
                                                    if (context.mounted) {
                                                      if (success) {
                                                        CustomToast.show(
                                                          context,
                                                          message: val
                                                              ? 'Administrador habilitado'
                                                              : 'Administrador deshabilitado',
                                                          type: ToastType.success,
                                                        );
                                                      } else {
                                                        CustomToast.show(
                                                          context,
                                                          message: 'Error al cambiar estado',
                                                          type: ToastType.error,
                                                        );
                                                      }
                                                    }
                                                  }
                                                },
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
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
