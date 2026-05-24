import 'package:dio/dio.dart';
import '../../../auth/models/user_model.dart';
import '../models/role_model.dart';

class StaffRepository {
  final Dio _dio;

  StaffRepository(this._dio);

  Future<List<UserModel>> getStaff(String barId) async {
    final response = await _dio.get('/users/bar/$barId');
    final list = response.data as List? ?? [];
    return list.map((u) => UserModel.fromJson(u as Map<String, dynamic>)).toList();
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final response = await _dio.post('/users', data: data);
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> updateUser(String userId, Map<String, dynamic> updates) async {
    final response = await _dio.patch('/users/$userId', data: updates);
    return UserModel.fromJson(response.data);
  }

  Future<UserModel> deleteUser(String userId) async {
    final response = await _dio.delete('/users/$userId');
    return UserModel.fromJson(response.data);
  }

  Future<List<RoleModel>> getRoles(String barId) async {
    final response = await _dio.get('/roles/bar/$barId');
    final list = response.data as List? ?? [];
    return list.map((r) => RoleModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<RoleModel> createRole(String nombre, List<String> permisoIds) async {
    final response = await _dio.post('/roles', data: {
      'nombre': nombre,
      'permiso_ids': permisoIds,
    });
    return RoleModel.fromJson(response.data);
  }

  Future<RoleModel> updateRole(String id, String nombre, List<String> permisoIds) async {
    final response = await _dio.patch('/roles/$id', data: {
      'nombre': nombre,
      'permiso_ids': permisoIds,
    });
    return RoleModel.fromJson(response.data);
  }

  Future<void> deleteRole(String id) async {
    await _dio.delete('/roles/$id');
  }

  Future<List<PermissionModel>> getPermissions() async {
    final response = await _dio.get('/permissions');
    final list = response.data as List? ?? [];
    return list.map((p) => PermissionModel.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<String> uploadImage(String filePath, String folder) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/uploads/image?folder=$folder', data: formData);
    return response.data['url'] as String;
  }

  Future<UserModel> updateSelfProfile({String? password, String? fotoUrl}) async {
    final Map<String, dynamic> updates = {};
    if (password != null && password.isNotEmpty) {
      updates['password'] = password;
    }
    if (fotoUrl != null) {
      updates['foto_url'] = fotoUrl;
    }
    final response = await _dio.patch('/users/profile/update', data: updates);
    return UserModel.fromJson(response.data);
  }
}
