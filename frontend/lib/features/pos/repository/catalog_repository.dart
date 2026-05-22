import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/local_db/hive_entities/category_hive.dart';
import '../../../core/local_db/hive_entities/product_hive.dart';
import '../../../core/local_db/hive_entities/sync_queue_hive.dart';
import '../../../core/local_db/mappers/catalog_mapper.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';

class CatalogRepository {
  final Dio _dio;

  CatalogRepository(this._dio);

  // =========================================================================
  // CATEGORIES
  // =========================================================================

  /// Devuelve un Stream reactivo de la BD local (0ms lag) y sincroniza en background
  Stream<List<CategoryModel>> watchCategories({bool isAdmin = false}) async* {
    // 1. Disparar sync en background
    _syncCategories(isAdmin: isAdmin).catchError((_) {});

    final box = Hive.box<CategoryHive>('categories');
    
    // 2. Emitir valor inicial instantáneo
    yield _getCategoriesSorted(box);

    // 3. Emitir nuevos valores cada vez que haya un cambio en la caja
    await for (var _ in box.watch()) {
      yield _getCategoriesSorted(box);
    }
  }

  List<CategoryModel> _getCategoriesSorted(Box<CategoryHive> box) {
    final list = box.values.toList();
    list.sort((a, b) => a.orden.compareTo(b.orden));
    return list.map((e) => e.toDomain()).toList();
  }

  Future<void> _syncCategories({bool isAdmin = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (isAdmin) queryParams['admin'] = 'true';
      
      final response = await _dio.get('/categories', queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final list = response.data as List? ?? [];
      final domainList = list.map((json) => CategoryModel.fromJson(json as Map<String, dynamic>)).toList();
      
      // Guardar en Hive
      final box = Hive.box<CategoryHive>('categories');
      await box.clear();
      
      final Map<String, CategoryHive> map = {
        for (var e in domainList) e.id: e.toHive()
      };
      await box.putAll(map);
    } catch (e) {
      // Ignorar fallo de red
    }
  }

  // =========================================================================
  // PRODUCTS
  // =========================================================================

  /// Devuelve un Stream reactivo de productos y sincroniza
  Stream<List<ProductModel>> watchProducts({String? categoryId, bool isAdmin = false}) async* {
    _syncProducts(categoryId: categoryId, isAdmin: isAdmin).catchError((_) {});
    
    final box = Hive.box<ProductHive>('products');
    
    yield _getFilteredProducts(box, categoryId);

    await for (var _ in box.watch()) {
      yield _getFilteredProducts(box, categoryId);
    }
  }

  List<ProductModel> _getFilteredProducts(Box<ProductHive> box, String? categoryId) {
    final domainList = box.values.map((e) => e.toDomain()).toList();
    if (categoryId != null) {
      return domainList.where((p) => p.categoriaId == categoryId).toList();
    }
    return domainList;
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

      final box = Hive.box<ProductHive>('products');
      await box.clear();
      
      final Map<String, ProductHive> map = {
        for (var e in domainList) e.id: e.toHive()
      };
      await box.putAll(map);
    } catch (e) {
      // Ignorar fallo de red
    }
  }

  // =========================================================================
  // CHECKOUT (POS)
  // =========================================================================

  /// Registra una nueva transacción de venta en el POS del bar
  Future<void> checkout({
    required String metodoPago,
    required List<CartItem> items,
  }) async {
    final payload = {
      'metodo_pago': metodoPago,
      'items': items.map((item) {
        return {
          'variante_id': item.variant.id,
          'cantidad': item.quantity,
          'tarifa_id': item.tarifaId,
          'dama_id': item.damaId,
          'es_invitacion': item.esInvitacion,
        };
      }).toList(),
    };

    try {
      await _dio.post('/ventas', data: payload);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout || 
          e.type == DioExceptionType.connectionError || 
          e.type == DioExceptionType.unknown) {
        
        // Guardar en la cola local si no hay internet
        final box = Hive.box<SyncQueueTaskHive>('sync_queue');
        final task = SyncQueueTaskHive()
          ..method = 'POST'
          ..endpoint = '/ventas'
          ..payload = jsonEncode(payload)
          ..createdAt = DateTime.now()
          ..retries = 0;
        await box.add(task);
        return; // Termina exitosamente para la UI
      }
      
      final errorResponse = e.response?.data;
      String errorMessage = 'Error al registrar la venta';
      if (errorResponse != null && errorResponse['message'] != null) {
        errorMessage = errorResponse['message'].toString();
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Guardar en la cola local por seguridad ante otros fallos
      final box = Hive.box<SyncQueueTaskHive>('sync_queue');
      final task = SyncQueueTaskHive()
        ..method = 'POST'
        ..endpoint = '/ventas'
        ..payload = jsonEncode(payload)
        ..createdAt = DateTime.now()
        ..retries = 0;
      await box.add(task);
    }
  }
}

// Provider del repositorio del catálogo con Riverpod
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CatalogRepository(dio);
});
