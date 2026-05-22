import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../repository/catalog_repository.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repository/auth_repository.dart';
import 'dart:convert';
import '../../../core/storage/secure_storage_service.dart';

// =========================================================================
// DAMAS (USUARIOS)
// =========================================================================

final damasProvider = StreamProvider<List<UserModel>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.watchUsers().map((users) {
    return users.where((u) => u.rolNombre.toUpperCase() == 'DAMA').toList();
  });
});


// Proveedor reactivo para obtener las categorías (Modo Admin y POS)
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchCategories(isAdmin: true);
});

// Proveedor reactivo para obtener todos los productos del bar activo
final productsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchProducts(isAdmin: true);
});

// ID de categoría seleccionado actualmente para el POS (null representa "Todos")
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

// Proveedor reactivo que filtra los productos en memoria instantáneamente (0ms de lag) para el Admin
final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

  return productsAsync.whenData((products) {
    if (selectedCategoryId == null) {
      return products;
    }
    return products.where((p) => p.categoriaId == selectedCategoryId).toList();
  });
});

// =========================================================
// FILTROS ESTRICTOS PARA EL POS (Solo Activos)
// =========================================================
final posCategoriesProvider = Provider<AsyncValue<List<CategoryModel>>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.whenData((categories) {
    return categories.where((c) => c.disponible).toList();
  });
});

final posFilteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(filteredProductsProvider);
  return productsAsync.whenData((products) {
    return products
        .where((p) => p.disponible)
        .map((p) => ProductModel(
              id: p.id,
              nombre: p.nombre,
              descripcion: p.descripcion,
              fotoUrl: p.fotoUrl,
              categoriaId: p.categoriaId,
              disponible: p.disponible,
              variantes: p.variantes.where((v) => v.disponible).toList(),
            ))
        .where((p) => p.variantes.isNotEmpty) // No mostrar si no tiene variantes activas
        .toList();
  });
});
