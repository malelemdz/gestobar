import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/analytics_resumen_model.dart';
import '../models/product_ranking_model.dart';
import '../models/dama_ranking_model.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository(this._dio);

  Future<AnalyticsResumenModel> getResumenGeneral({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['fecha_inicio'] = startDate;
      if (endDate != null) queryParams['fecha_fin'] = endDate;

      final response = await _dio.get(
        '/estadisticas/resumen',
        queryParameters: queryParams,
      );

      return AnalyticsResumenModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al obtener resumen de estadísticas';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para obtener las estadísticas');
    }
  }

  Future<List<ProductRankingModel>> getRankingProductos({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['fecha_inicio'] = startDate;
      if (endDate != null) queryParams['fecha_fin'] = endDate;

      final response = await _dio.get(
        '/estadisticas/ranking-productos',
        queryParameters: queryParams,
      );

      final list = response.data as List? ?? [];
      return list.map((json) => ProductRankingModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al obtener ranking de productos';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para obtener el ranking de productos');
    }
  }

  Future<List<DamaRankingModel>> getRankingDamas({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['fecha_inicio'] = startDate;
      if (endDate != null) queryParams['fecha_fin'] = endDate;

      final response = await _dio.get(
        '/estadisticas/ranking-damas',
        queryParameters: queryParams,
      );

      final list = response.data as List? ?? [];
      return list.map((json) => DamaRankingModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al obtener ranking de damas';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para obtener el ranking de damas');
    }
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AnalyticsRepository(dio);
});
