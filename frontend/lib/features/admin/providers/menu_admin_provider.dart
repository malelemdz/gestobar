import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../pos/providers/catalog_provider.dart';
import '../data/repositories/menu_admin_repository.dart';

class MenuAdminState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  MenuAdminState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  MenuAdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return MenuAdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final menuAdminRepositoryProvider = Provider<MenuAdminRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MenuAdminRepository(dio);
});

final menuAdminProvider = StateNotifierProvider<MenuAdminNotifier, MenuAdminState>((ref) {
  final repository = ref.watch(menuAdminRepositoryProvider);
  return MenuAdminNotifier(repository, ref);
});

class MenuAdminNotifier extends StateNotifier<MenuAdminState> {
  final MenuAdminRepository _repository;
  final Ref _ref;

  MenuAdminNotifier(this._repository, this._ref) : super(MenuAdminState());

  void _clearState() {
    state = state.copyWith(isLoading: false, errorMessage: null, successMessage: null);
  }

  // --- GESTIÓN DE CATEGORÍAS ---

  Future<bool> createCategory(String nombre, int orden) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createCategory(nombre, orden);
      _ref.invalidate(categoriesProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Categoría creada con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateCategory(String id, String nombre, int orden, {bool? disponible}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateCategory(id, nombre, orden, disponible: disponible);
      _ref.invalidate(categoriesProvider);
      _ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Categoría actualizada con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteCategory(id);
      _ref.invalidate(categoriesProvider);
      _ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Categoría eliminada con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // --- GESTIÓN DE PRODUCTOS ---

  Future<bool> createProduct({
    required String nombre,
    String? descripcion,
    String? fotoUrl,
    required String categoriaId,
    bool? disponible,
    required List<Map<String, dynamic>> variantes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.createProduct(
        nombre: nombre,
        descripcion: descripcion,
        fotoUrl: fotoUrl,
        categoriaId: categoriaId,
        disponible: disponible,
        variantes: variantes,
      );
      _ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Producto creado con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateProduct(id, updates);
      _ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Producto actualizado con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteProduct(id);
      _ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Producto eliminado con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // --- GESTIÓN DE VARIANTES ---

  Future<bool> addVariant(String productId, Map<String, dynamic> variantData) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.addVariant(productId, variantData);
      _ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Variante agregada con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateVariant(String variantId, Map<String, dynamic> variantData) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.updateVariant(variantId, variantData);
      _ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Variante actualizada con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteVariant(String variantId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.deleteVariant(variantId);
      _ref.invalidate(productsProvider);
      state = state.copyWith(isLoading: false, successMessage: 'Variante eliminada con éxito');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // --- COMPRESIÓN CENTRALIZADA ---

  Future<String?> uploadImage(String filePath, String folder) async {
    state = state.copyWith(isLoading: true);
    try {
      final url = await _repository.uploadImage(filePath, folder);
      state = state.copyWith(isLoading: false);
      return url;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error al subir imagen: ${e.toString()}');
      return null;
    }
  }
}
