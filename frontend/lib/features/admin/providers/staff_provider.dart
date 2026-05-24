import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/models/user_model.dart';
import '../data/models/role_model.dart';
import '../data/repositories/staff_repository.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return StaffRepository(dio);
});

final staffListProvider = StateNotifierProvider<StaffNotifier, AsyncValue<List<UserModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final repo = ref.watch(staffRepositoryProvider);

  String? activeBarId;
  if (authState is AuthAuthenticated) {
    activeBarId = authState.activeBarId ?? authState.user.barId;
  }

  return StaffNotifier(
    repository: repo,
    barId: activeBarId,
  );
});

final rolesListProvider = StateNotifierProvider<RolesNotifier, AsyncValue<List<RoleModel>>>((ref) {
  final authState = ref.watch(authProvider);
  final repo = ref.watch(staffRepositoryProvider);

  String? activeBarId;
  if (authState is AuthAuthenticated) {
    activeBarId = authState.activeBarId ?? authState.user.barId;
  }

  return RolesNotifier(
    repository: repo,
    barId: activeBarId,
  );
});

final permissionsListProvider = FutureProvider<List<PermissionModel>>((ref) async {
  final repo = ref.watch(staffRepositoryProvider);
  return repo.getPermissions();
});

class StaffNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final StaffRepository repository;
  final String? barId;

  StaffNotifier({required this.repository, this.barId}) : super(const AsyncValue.loading()) {
    if (barId != null) {
      loadStaff();
    }
  }

  Future<void> loadStaff() async {
    if (barId == null) return;
    try {
      state = const AsyncValue.loading();
      final list = await repository.getStaff(barId!);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createStaff(Map<String, dynamic> data) async {
    try {
      final newUser = await repository.createUser({
        ...data,
        'bar_id': barId,
      });
      state.whenData((list) {
        state = AsyncValue.data([...list, newUser]);
      });
      return true;
    } catch (e) {
      print('Create staff error: $e');
      return false;
    }
  }

  Future<bool> updateStaff(String userId, Map<String, dynamic> updates) async {
    try {
      final updatedUser = await repository.updateUser(userId, updates);
      state.whenData((list) {
        state = AsyncValue.data(
          list.map((u) => u.id == userId ? updatedUser : u).toList(),
        );
      });
      return true;
    } catch (e) {
      print('Update staff error: $e');
      return false;
    }
  }

  Future<bool> toggleStaffStatus(String userId, bool active) async {
    // Cambiar localmente de forma optimista
    state.whenData((list) {
      state = AsyncValue.data(
        list.map((u) => u.id == userId ? u.copyWith(estado: active) : u).toList(),
      );
    });

    try {
      await repository.updateUser(userId, {'estado': active});
      return true;
    } catch (e) {
      print('Toggle status error: $e');
      // Revertir en caso de error
      loadStaff();
      return false;
    }
  }

  Future<bool> deleteStaff(String userId) async {
    try {
      final softDeletedUser = await repository.deleteUser(userId);
      state.whenData((list) {
        state = AsyncValue.data(
          list.map((u) => u.id == userId ? softDeletedUser : u).toList(),
        );
      });
      return true;
    } catch (e) {
      print('Soft delete staff error: $e');
      return false;
    }
  }

  Future<String?> uploadPhoto(String filePath) async {
    try {
      final url = await repository.uploadImage(filePath, 'usuarios');
      return url;
    } catch (e) {
      print('Upload user image error: $e');
      return null;
    }
  }
}

class RolesNotifier extends StateNotifier<AsyncValue<List<RoleModel>>> {
  final StaffRepository repository;
  final String? barId;

  RolesNotifier({required this.repository, this.barId}) : super(const AsyncValue.loading()) {
    if (barId != null) {
      loadRoles();
    }
  }

  Future<void> loadRoles() async {
    if (barId == null) return;
    try {
      state = const AsyncValue.loading();
      final list = await repository.getRoles(barId!);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> createRole(String nombre, List<String> permisoIds) async {
    try {
      final newRole = await repository.createRole(nombre, permisoIds);
      state.whenData((list) {
        state = AsyncValue.data([...list, newRole]);
      });
      return true;
    } catch (e) {
      print('Create role error: $e');
      return false;
    }
  }

  Future<bool> updateRole(String id, String nombre, List<String> permisoIds) async {
    try {
      final updatedRole = await repository.updateRole(id, nombre, permisoIds);
      state.whenData((list) {
        state = AsyncValue.data(
          list.map((r) => r.id == id ? updatedRole : r).toList(),
        );
      });
      return true;
    } catch (e) {
      print('Update role error: $e');
      return false;
    }
  }

  Future<bool> deleteRole(String id) async {
    try {
      await repository.deleteRole(id);
      state.whenData((list) {
        state = AsyncValue.data(
          list.where((r) => r.id != id).toList(),
        );
      });
      return true;
    } catch (e) {
      print('Delete role error: $e');
      return false;
    }
  }
}
