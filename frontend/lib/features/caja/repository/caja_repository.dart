import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/caja_model.dart';
import '../models/venta_model.dart';

class CajaRepository {
  final Dio _dio;

  CajaRepository(this._dio);

  /// Obtiene el estado actual de la caja (si hay un turno abierto o no, con todas sus métricas Bento)
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

  /// Abre un nuevo turno de caja registrando el efectivo inicial obligatorio en la gaveta
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

  /// Cierra el turno activo de forma autónoma sin inputs
  Future<Map<String, dynamic>> cierre() async {
    try {
      final response = await _dio.post('/cajas/cierre');
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

  /// Registra un ingreso o egreso de caja chica en el turno activo
  Future<CajaMovimientoModel> registrarMovimiento({
    required double monto,
    required String tipo,
    required String metodoPago,
    required String concepto,
  }) async {
    try {
      final response = await _dio.post(
        '/cajas/movimientos',
        data: {
          'monto': monto,
          'tipo': tipo,
          'metodo_pago': metodoPago,
          'concepto': concepto,
        },
      );
      return CajaMovimientoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al registrar movimiento';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar al servidor para registrar el movimiento');
    }
  }

  /// Obtiene la lista agregada de comisiones de damas en el turno
  Future<List<dynamic>> getDamaComisiones(String cajaId) async {
    try {
      final response = await _dio.get('/cajas/$cajaId/comisiones-damas');
      return response.data as List<dynamic>? ?? [];
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al obtener comisiones';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar al servidor para obtener comisiones');
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

  /// Obtiene la tabla en vivo de las ventas del turno actual y sus totales
  Future<Map<String, dynamic>> getActiveVentas() async {
    try {
      final response = await _dio.get('/ventas/caja/activa');
      final data = response.data as Map<String, dynamic>;
      final ventas = (data['ventas'] as List? ?? [])
          .map((json) => VentaModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return {
        'caja_id': data['caja_id'] ?? '',
        'totales': data['totales'] ?? { 'efectivo': 0, 'tarjeta': 0, 'tr_qr': 0, 'general': 0 },
        'ventas': ventas,
      };
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al cargar ventas en vivo';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para cargar ventas en vivo');
    }
  }
}

// Inyección de Riverpod para el repositorio de caja
final cajaRepositoryProvider = Provider<CajaRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CajaRepository(dio);
});
