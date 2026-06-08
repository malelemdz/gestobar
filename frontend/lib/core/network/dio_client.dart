import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

import 'session_events.dart';

String? _getUserAgent() {
  if (kIsWeb) {
    return null; // Permite que el navegador envíe su User-Agent nativo real
  }
  try {
    if (Platform.isAndroid) {
      return 'Mozilla/5.0 (Android; Mobile) GestobarApp';
    } else if (Platform.isIOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) GestobarApp';
    } else if (Platform.isMacOS) {
      return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) GestobarApp';
    } else if (Platform.isWindows) {
      return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) GestobarApp';
    } else if (Platform.isLinux) {
      return 'Mozilla/5.0 (X11; Linux x86_64) GestobarApp';
    }
  } catch (_) {}
  return 'Mozilla/5.0 (Dart) GestobarApp';
}

final dioProvider = Provider<Dio>((ref) {
  final userAgent = _getUserAgent();
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent':? userAgent,
      },
    ),
  );

  final storage = ref.watch(secureStorageProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Inyectar JWT Token de manera dinámica si existe
        final token = await storage.read(ApiConstants.keyJwtToken);
        if (token != null && token.isNotEmpty) {
          options.headers[ApiConstants.headerAuthorization] = 'Bearer $token';
        }

        // Inyectar Tenant ID (x-bar-id) para garantizar aislamiento estricto en el backend
        final barId = await storage.read(ApiConstants.keyActiveBarId);
        if (barId != null && barId.isNotEmpty) {
          options.headers[ApiConstants.headerBarId] = barId;
        }

        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Manejo inteligente de sesión expirada (401 Unauthorized)
        if (error.response?.statusCode == 401) {
          await storage.clearAll();
          logoutController.add(null);
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
