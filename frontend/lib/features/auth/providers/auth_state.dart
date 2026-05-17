import '../models/user_model.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final UserModel user;
  final String? activeBarId;

  const AuthAuthenticated({
    required this.token,
    required this.user,
    this.activeBarId,
  });

  AuthAuthenticated copyWith({
    String? token,
    UserModel? user,
    String? activeBarId,
  }) {
    return AuthAuthenticated(
      token: token ?? this.token,
      user: user ?? this.user,
      activeBarId: activeBarId ?? this.activeBarId,
    );
  }
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
