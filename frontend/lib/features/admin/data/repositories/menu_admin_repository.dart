import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../pos/models/category_model.dart';
import '../../../pos/models/product_model.dart';

class MenuAdminRepository {
  final Dio _dio;

  MenuAdminRepository(this._dio);

  // --- GESTIÓN DE CATEGORÍAS ---

  Future<CategoryModel> createCategory(String nombre, int orden) async {
    final response = await _dio.post('/categories', data: {
      'nombre': nombre,
      'orden': orden,
    });
    return CategoryModel.fromJson(response.data);
  }

  Future<CategoryModel> updateCategory(String id, String nombre, int orden, {bool? disponible}) async {
    final data = <String, dynamic>{
      'nombre': nombre,
      'orden': orden,
    };
    if (disponible != null) {
      data['disponible'] = disponible;
    }
    final response = await _dio.patch('/categories/$id', data: data);
    return CategoryModel.fromJson(response.data);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }

  // --- GESTIÓN DE PRODUCTOS ---

  Future<ProductModel> createProduct({
    required String nombre,
    String? descripcion,
    String? fotoUrl,
    required String categoriaId,
    bool? disponible,
    required List<Map<String, dynamic>> variantes,
  }) async {
    final response = await _dio.post('/products', data: {
      'nombre': nombre,
      'descripcion': descripcion,
      'foto_url': fotoUrl,
      'categoria_id': categoriaId,
      if (disponible != null) 'disponible': disponible,
      'variantes': variantes,
    });
    return ProductModel.fromJson(response.data);
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> updates) async {
    final response = await _dio.patch('/products/$id', data: updates);
    return ProductModel.fromJson(response.data);
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/$id');
  }

  // --- GESTIÓN DE VARIANTES ---

  Future<void> addVariant(String productId, Map<String, dynamic> variantData) async {
    await _dio.post('/products/$productId/variants', data: variantData);
  }

  Future<void> updateVariant(String variantId, Map<String, dynamic> variantData) async {
    await _dio.patch('/products/variants/$variantId', data: variantData);
  }

  Future<void> deleteVariant(String variantId) async {
    await _dio.delete('/products/variants/$variantId');
  }

  // --- COMPRESIÓN CENTRALIZADA DE IMÁGENES ---

  Future<String> uploadImage(String filePath, String folder) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/uploads/image?folder=$folder', data: formData);
    return response.data['url'] as String;
  }
}
