import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/local_db/isar_provider.dart';
import '../../../core/local_db/entities/category_entity.dart';
import '../../../core/local_db/entities/product_entity.dart';
import '../../../core/local_db/mappers/catalog_mapper.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';

class CatalogRepository {
  final Dio _dio;
  final Isar _isar;

  CatalogRepository(this._dio, this._isar);

  /// Devuelve un Stream reactivo de la BD local (0ms lag) y sincroniza en background
  Stream<List<CategoryModel>> watchCategories({bool isAdmin = false}) {
    // 1. Disparar sync en background
    _syncCategories(isAdmin: isAdmin).catchError((_) {});

    // 2. Retornar el observable de Isar transformado al Dominio
    return _isar.categoryIsars
        .where()
        .sortByOrden()
        .watch(fireImmediately: true)
        .map((isarList) => isarList.map((e) => e.toDomain()).toList());
  }

  Future<void> _syncCategories({bool isAdmin = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isAdmin) queryParams['admin'] = 'true';
      
      final response = await _dio.get('/categories', queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final list = response.data as List? ?? [];
      final domainList = list.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      
      // Guardar en la caché local
      await _isar.writeTxn(() async {
        await _isar.categoryIsars.clear();
        await _isar.categoryIsars.putAll(domainList.map((e) => e.toIsar()).toList());
      });
    } catch (e) {
      // Si falla la red, ignoramos. La UI seguirá mostrando la caché de Isar
    }
  }

  /// Devuelve un Stream reactivo de productos y sincroniza
  Stream<List<ProductModel>> watchProducts({String? categoryId, bool isAdmin = false}) {
    _syncProducts(categoryId: categoryId, isAdmin: isAdmin).catchError((_) {});
    
    // Si se filtra por categoría, aplicamos el filtro a la query de Isar
    final query = _isar.productIsars.where();
    
    return query
        .watch(fireImmediately: true)
        .map((isarList) {
          final domainList = isarList.map((e) => e.toDomain()).toList();
          if (categoryId != null) {
            return domainList.where((p) => p.categoriaId == categoryId).toList();
          }
          return domainList;
        });
  }

  Future<void> _syncProducts({String? categoryId, bool isAdmin = false}) async {
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
      final domainList = list.map((json) => ProductModel.fromJson(json as Map<String, dynamic>)).toList();

      await _isar.writeTxn(() async {
        await _isar.productIsars.clear();
        await _isar.productIsars.putAll(domainList.map((e) => e.toIsar()).toList());
      });
    } catch (e) {
      // Ignorar fallo de red
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
  final isar = ref.watch(isarProvider);
  return CatalogRepository(dio, isar);
});
