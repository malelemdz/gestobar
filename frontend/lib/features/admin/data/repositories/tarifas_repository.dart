import 'package:dio/dio.dart';
import '../models/tarifa_model.dart';

class TarifasRepository {
  final Dio _dio;

  TarifasRepository(this._dio);

  Future<List<TarifaModel>> getTarifas(String barId) async {
    final response = await _dio.get('/tarifas/bar/$barId');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => TarifaModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<TarifaModel> createTarifa(String barId, String nombre, bool esDefault, bool activo) async {
    final response = await _dio.post('/tarifas', data: {
      'bar_id': barId,
      'nombre': nombre,
      'es_default': esDefault,
      'activo': activo,
    });
    return TarifaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TarifaModel> updateTarifa(String id, String nombre, bool esDefault, bool activo) async {
    final response = await _dio.put('/tarifas/$id', data: {
      'nombre': nombre,
      'es_default': esDefault,
      'activo': activo,
    });
    return TarifaModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTarifa(String id) async {
    await _dio.delete('/tarifas/$id');
  }
}
