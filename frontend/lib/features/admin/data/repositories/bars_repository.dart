import 'package:dio/dio.dart';
import '../models/bar_model.dart';

class BarsRepository {
  final Dio _dio;
  
  BarsRepository(this._dio);

  Future<BarModel> getBarInfo(String barId) async {
    final response = await _dio.get('/bars/$barId');
    return BarModel.fromJson(response.data);
  }

  Future<BarModel> updateBar(String barId, Map<String, dynamic> updates) async {
    final response = await _dio.patch('/bars/$barId', data: updates);
    return BarModel.fromJson(response.data);
  }

  Future<String> uploadImage(String filePath, String folder) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/uploads/image?folder=$folder', data: formData);
    return response.data['url'] as String;
  }
}
