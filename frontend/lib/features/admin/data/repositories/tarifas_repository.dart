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
}
