import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/network/session_events.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _storage;

  AuthNotifier(this._repository, this._storage) : super(const AuthInitial()) {
    _tryRestoreSession();
    // Escuchar eventos globales de logout (ej. error 401 interceptado)
    logoutController.stream.listen((_) {
      logout();
    });
  }

  /// Intenta recuperar de forma asíncrona la sesión almacenada en el llavero/Keychain
  Future<void> _tryRestoreSession() async {
    try {
      final token = await _storage.read(ApiConstants.keyJwtToken);
      final userString = await _storage.read(ApiConstants.keyUserProfile);
      final activeBarId = await _storage.read(ApiConstants.keyActiveBarId);

      if (token != null && userString != null) {
        final userJson = jsonDecode(userString) as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);
        
        // Establecer sesión local de forma optimista
        state = AuthAuthenticated(
          token: token,
          user: user,
          activeBarId: user.rolNombre.toUpperCase() == 'SUPERADMIN'
              ? null
              : (activeBarId ?? user.barId),
        );

        // Intentar renovar el token silenciosamente con el servidor
        try {
          final (newToken, freshUser) = await _repository.renewToken();

          await _storage.write(ApiConstants.keyJwtToken, newToken);
          await _storage.write(ApiConstants.keyUserProfile, jsonEncode(freshUser.toJson()));

          state = AuthAuthenticated(
            token: newToken,
            user: freshUser,
            activeBarId: freshUser.rolNombre.toUpperCase() == 'SUPERADMIN'
                ? null
                : (activeBarId ?? freshUser.barId),
          );
        } catch (e) {
          // Si el servidor indica explícitamente no autorizado/vencido, desloguear
          final errStr = e.toString();
          if (errStr.contains('Unauthorized') || errStr.contains('401') || errStr.contains('renovar sesión')) {
            await logout();
          }
          // Si es error de conexión u otro, se mantiene la sesión optimista local
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  /// Ejecuta el flujo atómico de inicio de sesión
  Future<void> login(String username, String password) async {
    state = const AuthLoading();
    try {
      final (token, user) = await _repository.login(username, password);

      // Persistir de manera segura las credenciales y perfil
      await _storage.write(ApiConstants.keyJwtToken, token);
      await _storage.write(ApiConstants.keyUserProfile, jsonEncode(user.toJson()));
      
      if (user.barId != null) {
        await _storage.write(ApiConstants.keyActiveBarId, user.barId!);
      } else {
        await _storage.delete(ApiConstants.keyActiveBarId);
      }

      state = AuthAuthenticated(
        token: token,
        user: user,
        activeBarId: user.rolNombre.toUpperCase() == 'SUPERADMIN' ? null : user.barId,
      );
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Cambia de bar activo en caliente (útil para SuperAdmins o dueños de múltiples locales)
  Future<void> selectBar(String? barId) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      if (barId == null) {
        await _storage.delete(ApiConstants.keyActiveBarId);
      } else {
        await _storage.write(ApiConstants.keyActiveBarId, barId);
      }
      state = AuthAuthenticated(
        token: currentState.token,
        user: currentState.user,
        activeBarId: barId,
      );
    }
  }

  /// Actualiza el perfil del usuario autenticado en caliente en el estado y almacenamiento (foto y opcionalmente password)
  Future<void> updateProfile({
    String? password,
    String? fotoUrl,
    String? nombre,
    String? apellido,
    String? username,
    String? identificacion,
    String? celular,
    String? nacionalidad,
    String? direccion,
    String? genero,
  }) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      final Map<String, dynamic> updates = {};
      if (password != null && password.isNotEmpty) {
        updates['password'] = password;
      }
      if (fotoUrl != null) {
        updates['foto_url'] = fotoUrl;
      }
      if (nombre != null) {
        updates['nombre'] = nombre;
      }
      if (apellido != null) {
        updates['apellido'] = apellido;
      }
      if (username != null) {
        updates['username'] = username;
      }
      if (identificacion != null) {
        updates['identificacion'] = identificacion;
      }
      if (celular != null) {
        updates['celular'] = celular;
      }
      if (nacionalidad != null) {
        updates['nacionalidad'] = nacionalidad;
      }
      if (direccion != null) {
        updates['direccion'] = direccion;
      }
      if (genero != null) {
        updates['genero'] = genero;
      }

      // Guardar en base de datos llamando al endpoint de autogestión
      final updatedUser = await _repository.updateSelfProfile(updates);

      // Actualizar en el llavero/Keychain seguro
      await _storage.write(ApiConstants.keyUserProfile, jsonEncode(updatedUser.toJson()));

      state = currentState.copyWith(user: updatedUser);
    }
  }

  /// Cierra la sesión activa limpiando todo almacenamiento seguro (Tenant ID, JWT, perfil)
  Future<void> logout() async {
    await _storage.clearAll();
    state = const AuthUnauthenticated();
  }
}

// Provider global de estado de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(repository, storage);
});
