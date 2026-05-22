import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../repository/catalog_repository.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repository/auth_repository.dart';
import '../../../core/local_db/hive_entities/user_hive.dart';
import '../../../core/local_db/mappers/user_mapper.dart';

// =========================================================================
// DAMAS (USUARIOS) - INSTANTÁNEO Y SILENCIOSO
// =========================================================================

class DamasNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final AuthRepository _repo;

  DamasNotifier(this._repo) : super(const AsyncLoading()) {
    _initData();
  }

  Future<void> _initData() async {
    try {
      final box = Hive.box<UserHive>('users');
      final localUsers = box.values.toList();
      
      if (localUsers.isNotEmpty) {
        // Si hay datos locales, los mostramos instantáneamente (0ms)
        _updateState(box);
        box.watch().listen((_) => _updateState(box));
        // Y sincronizamos en las sombras sin interrumpir la venta
        _repo.syncUsersSilently();
      } else {
        // FUENTE DE VERDAD: Si la base local está vacía, no asumimos nada. 
        // Bloqueamos la interfaz en estado de "Carga" hasta que el Servidor responda.
        await _repo.syncUsersSilently();
        _updateState(box);
        box.watch().listen((_) => _updateState(box));
      }
    } catch (e, st) {
      state = AsyncError('Error de sincronización', st);
    }
  }

  void _updateState(Box<UserHive> box) {
    final list = box.values.toList();
    final damas = list
        .map((e) => e.toDomain())
        .where((u) => u.rolNombre.toUpperCase() == 'DAMA')
        .toList();
    state = AsyncData(damas);
  }
}

final damasProvider = StateNotifierProvider<DamasNotifier, AsyncValue<List<UserModel>>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return DamasNotifier(authRepo);
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
