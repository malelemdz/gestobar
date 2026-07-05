import 'dart:io';
import 'package:flutter/foundation.dart';

// El entorno se inyecta en tiempo de build con --dart-define=ENVIRONMENT=stage
// Valores posibles: 'debug' | 'stage' | 'production'
const String _kEnvironment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'debug');

// URLs de la API por entorno — reemplaza con tus dominios reales cuando los tengas
const String _kStageUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api-stg.gestobar.app');
const String _kProductionUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api.gestobar.app');

class ApiConstants {
  // Resuelve la URL del backend según el entorno de build
  // El entorno se controla EXCLUSIVAMENTE con --dart-define=ENVIRONMENT=...
  // No usamos kDebugMode para no interferir con `flutter run --release`
  static String get baseUrl {
    if (_kEnvironment == 'debug') {
      if (kIsWeb) return 'http://localhost:3000';
      try {
        if (Platform.isAndroid) return 'http://10.0.2.2:3000'; // Emulador Android
      } catch (_) {}
      return 'http://localhost:3000';
    }

    // En stage o production usa la URL inyectada en el build
    if (_kEnvironment == 'stage') return _kStageUrl;
    return _kProductionUrl;
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
  static const String selectBar = '/users/bar';
  static const String currentStaff = '/users/profile';
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

