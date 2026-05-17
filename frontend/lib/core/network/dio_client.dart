import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
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
          // Nota: El gestor de estado detectará que el token es nulo y forzará
          // el redibujado de la interfaz hacia el login de forma reactiva.
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});
