import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _storage;

  AuthNotifier(this._repository, this._storage) : super(const AuthInitial()) {
    _tryRestoreSession();
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
        
        state = AuthAuthenticated(
          token: token,
          user: user,
          activeBarId: activeBarId ?? user.barId,
        );
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
      }

      state = AuthAuthenticated(
        token: token,
        user: user,
        activeBarId: user.barId,
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
      state = currentState.copyWith(activeBarId: barId);
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
