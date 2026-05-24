import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Resuelve la URL del servidor NestJS backend de forma inteligente
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    try {
      if (Platform.isAndroid) {
        // IP de loopback especial para el Android Emulator
        return 'http://10.0.2.2:3000';
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }

  static String? resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '$baseUrl$url';
  }

  static String get wsUrl {
    return baseUrl;
  }

  // Rutas de API REST
  static const String login = '/auth/login';
  static const String selectBar = '/users/bar'; // Para cambiar o asignar bar activo si es necesario
  static const String currentStaff = '/users/profile'; // Datos de perfil del staff logueado
  static const String bars = '/bars';

  // Cabeceras HTTP Clave
  static const String headerAuthorization = 'Authorization';
  static const String headerBarId = 'x-bar-id';

  // Claves de Almacenamiento Seguro
  static const String keyJwtToken = 'jwt_token';
  static const String keyActiveBarId = 'active_bar_id';
  static const String keyActiveBarSlug = 'active_bar_slug';
  static const String keyUserProfile = 'user_profile';
}
