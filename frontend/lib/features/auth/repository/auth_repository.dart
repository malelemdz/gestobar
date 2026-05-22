import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/local_db/hive_entities/user_hive.dart';
import '../../../core/local_db/mappers/user_mapper.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  /// Autentica al usuario en el backend multi-tenant y retorna el token y perfil
  Future<(String token, UserModel user)> login(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      
      // La respuesta del login devuelve el perfil del usuario estructurado
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      return (token, user);
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al iniciar sesión';
      
      if (errorResponse != null && errorResponse['message'] != null) {
        final message = errorResponse['message'];
        errorMessage = message is List ? message.join(', ') : message.toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor de Gestobar');
    }
  }

  // =========================================================================
  // USUARIOS (HIVE OFFLINE-FIRST)
  // =========================================================================

  Future<void> syncUsersSilently() async {
    try {
      final response = await _dio.get('/users');
      final list = response.data as List? ?? [];
      final domainList = list.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
      
      // Guardar en Hive
      final box = Hive.box<UserHive>('users');
      await box.clear();
      
      final Map<String, UserHive> map = {
        for (var e in domainList) e.id: e.toHive()
      };
      await box.putAll(map);
    } catch (e) {
      // Ignorar fallo silenciosamente
    }
  }

  // =========================================================================
  // ANTIGUO METODO DIRECTO (Mantenido por compatibilidad si se usa en otro lado)
  // =========================================================================

  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _dio.get('/users');
      final list = response.data as List? ?? [];
      return list.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al cargar usuarios';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para obtener los usuarios');
    }
  }

  /// Actualiza los datos de un usuario en el backend
  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/users/$id', data: data);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al actualizar perfil';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para actualizar el perfil');
    }
  }
}


// Inyección del repositorio con Riverpod
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
