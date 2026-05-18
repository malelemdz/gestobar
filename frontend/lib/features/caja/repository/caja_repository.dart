import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/caja_model.dart';

class CajaRepository {
  final Dio _dio;

  CajaRepository(this._dio);

  /// Obtiene el estado actual de la caja (si hay un turno abierto o no)
  Future<EstadoCajaResponse> getEstado() async {
    try {
      final response = await _dio.get('/cajas/estado');
      return EstadoCajaResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al obtener estado de caja';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para obtener el estado de caja');
    }
  }

  /// Abre un nuevo turno de caja registrando el efectivo inicial en la gaveta
  Future<CajaModel> apertura(double montoInicial) async {
    try {
      final response = await _dio.post(
        '/cajas/apertura',
        data: {'monto_inicial': montoInicial},
      );
      return CajaModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al abrir caja';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar al servidor para abrir la caja');
    }
  }

  /// Cierra el turno activo, calculando ventas, comisiones y arqueo físico
  Future<Map<String, dynamic>> cierre(double montoFinal) async {
    try {
      final response = await _dio.post(
        '/cajas/cierre',
        data: {'monto_final': montoFinal},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al cerrar caja';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar al servidor para cerrar la caja');
    }
  }

  /// Obtiene la lista histórica de turnos cerrados del bar
  Future<List<CajaModel>> getHistory() async {
    try {
      final response = await _dio.get('/cajas');
      final list = response.data as List? ?? [];
      return list.map((json) => CajaModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al cargar historial de caja';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para cargar el historial');
    }
  }
}

// Inyección de Riverpod para el repositorio de caja
final cajaRepositoryProvider = Provider<CajaRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CajaRepository(dio);
});
