import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';


class CatalogRepository {
  final Dio _dio;

  CatalogRepository(this._dio);

  Future<List<CategoryModel>> getCategories({bool isAdmin = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isAdmin) queryParams['admin'] = 'true';
      
      final response = await _dio.get('/categories', queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final list = response.data as List? ?? [];
      return list.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al cargar categorías');
    } catch (e) {
      throw Exception('No se pudo obtener las categorías de Gestobar');
    }
  }

  Future<List<ProductModel>> getProducts({String? categoryId, bool isAdmin = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }
      if (isAdmin) {
        queryParams['admin'] = 'true';
      }
      final response = await _dio.get('/products', queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final list = response.data as List? ?? [];
      return list.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al cargar productos');
    } catch (e) {
      throw Exception('No se pudo obtener los productos de Gestobar');
    }
  }

  /// Registra una nueva transacción de venta en el POS del bar
  Future<void> checkout({
    required String metodoPago,
    required List<CartItem> items,
  }) async {
    try {
      final payload = {
        'metodo_pago': metodoPago,
        'items': items.map((item) {
          return {
            'variante_id': item.variant.id,
            'cantidad': item.quantity,
            'es_precio_b': item.esPrecioB,
            'dama_id': item.damaId,
            'es_invitacion': item.esInvitacion,
          };
        }).toList(),
      };

      await _dio.post('/ventas', data: payload);
    } on DioException catch (e) {
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al registrar la venta';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor para registrar la venta');
    }
  }
}


// Provider del repositorio del catálogo con Riverpod
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CatalogRepository(dio);
});
