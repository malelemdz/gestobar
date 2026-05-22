import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../repository/catalog_repository.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repository/auth_repository.dart';

// Proveedor futuro para obtener las damas de compañía activas para comisionar en el POS
final damasProvider = FutureProvider<List<UserModel>>((ref) async {
  final users = await ref.watch(authRepositoryProvider).getUsers();
  return users.where((u) => u.rolNombre.toUpperCase() == 'DAMA').toList();
});


// Proveedor futuro para obtener las categorías (Modo Admin para Flutter)
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(catalogRepositoryProvider).getCategories(isAdmin: true);
});

// Proveedor futuro para obtener todos los productos del bar activo (Modo Admin)
final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  return ref.watch(catalogRepositoryProvider).getProducts(isAdmin: true);
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
