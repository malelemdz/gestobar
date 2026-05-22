import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../pos/models/category_model.dart';
import '../../pos/models/product_model.dart';
import '../../pos/models/variant_model.dart';
import '../../pos/providers/catalog_provider.dart';
import '../../caja/providers/caja_provider.dart';
import '../../admin/providers/menu_admin_provider.dart';
import '../../admin/providers/tarifas_provider.dart';
import '../../admin/data/models/tarifa_model.dart';
import '../../../core/widgets/premium_fab.dart';

class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(filteredProductsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final menuAdminState = ref.watch(menuAdminProvider);

    // Listen to success/error messages from Menu Admin Provider
    ref.listen<MenuAdminState>(menuAdminProvider, (previous, next) {
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppTheme.colorSuccess,
          ),
        );
      }
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.colorDanger,
          ),
        );
      }
    });

    final filteredProducts = productsAsync.whenData((products) {
      if (_searchQuery.isEmpty) return products;
      return products
          .where((p) => p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF111317), // Deep Dark background
      floatingActionButton: PremiumFAB(
        label: 'Nuevo Producto',
        icon: Icons.add,
        onPressed: () => _openAddEditProductDialog(context, null),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth >= 900;

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unified Header
                    _buildHeader(theme, isTablet),

                    Expanded(
                      child: isTablet
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Bento Pane: Categories (30% or 320px)
                                Container(
                                  width: 320,
                                  padding: const EdgeInsets.fromLTRB(24, 0, 12, 24),
                                  child: _buildCategoriesPanel(context, categoriesAsync, selectedCategoryId, theme),
                                ),
                                // Elegant vertical divider line
                                Container(
                                  width: 1,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                                // Right Bento Pane: Products grid (70%)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 24, 24),
                                    child: _buildProductsPanel(context, filteredProducts, selectedCategoryId, theme),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                // Mobile view horizontal scroll categories
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: _buildMobileCategoriesCarousel(context, categoriesAsync, selectedCategoryId, theme),
                                ),
                                const SizedBox(height: 12),
                                // Expanded mobile products grid
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: _buildProductsPanel(context, filteredProducts, selectedCategoryId, theme),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                if (menuAdminState.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00F0FF),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================================================================
  // 🏷️ HEADER SECTION
  // =========================================================================
  Widget _buildHeader(ThemeData theme, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 16.0,
        vertical: 12.0,
      ),
      child: Row(
        children: [
          // Search Input Box
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2024),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar productos...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF00F0FF), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 📚 CATEGORIES PANEL (TABLET/DESKTOP LEFT SIDEBAR)
  // =========================================================================
  Widget _buildCategoriesPanel(
    BuildContext context,
    AsyncValue<List<CategoryModel>> categoriesAsync,
    String? selectedCategoryId,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CATEGORÍAS',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                  letterSpacing: 0.1,
                  color: AppTheme.liquidOnSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00F0FF), size: 20),
                onPressed: () => _openCategoryDialog(context, null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                // Sort categories by order just in case
                final sortedCategories = List<CategoryModel>.from(categories)
                  ..sort((a, b) => a.orden.compareTo(b.orden));

                return ListView.builder(
                  itemCount: sortedCategories.length + 1,
                  itemBuilder: (context, index) {
                    final bool isAll = index == 0;
                    final String? catId = isAll ? null : sortedCategories[index - 1].id;
                    final String nombre = isAll ? 'Ver Todo' : sortedCategories[index - 1].nombre;
                    final bool isSelected = selectedCategoryId == catId;

                    if (isAll) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: InkWell(
                          onTap: () {
                            ref.read(selectedCategoryIdProvider.notifier).state = null;
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E2024) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00F0FF).withOpacity(0.2) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.grid_view_rounded,
                                  color: isSelected ? const Color(0xFF00F0FF) : Colors.white24,
                                  size: 16,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  nombre,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : Colors.white60,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final cat = sortedCategories[index - 1];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedCategoryIdProvider.notifier).state = cat.id;
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Opacity(
                          opacity: cat.disponible ? 1.0 : 0.4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E2024) : const Color(0xFF131518),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00F0FF).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cat.nombre,
                                  style: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : Colors.white60,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Reorder arrow up
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward, size: 14, color: Colors.white30),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: index > 1
                                        ? () => _swapCategoriesOrder(
                                            context, cat, sortedCategories[index - 2])
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  // Reorder arrow down
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward, size: 14, color: Colors.white30),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: index < sortedCategories.length
                                        ? () => _swapCategoriesOrder(
                                            context, cat, sortedCategories[index])
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  // Visibility Toggle
                                  IconButton(
                                    icon: Icon(
                                      cat.disponible ? Icons.toggle_on : Icons.toggle_off, 
                                      size: 14, 
                                      color: cat.disponible ? const Color(0xFF00F0FF) : Colors.orangeAccent
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _toggleCategoryVisibility(context, cat),
                                  ),
                                  const SizedBox(width: 4),
                                  // Edit icon
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 14, color: Color(0xFF00F0FF)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _openCategoryDialog(context, cat),
                                  ),
                                  const SizedBox(width: 4),
                                  // Delete icon
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDeleteCategory(context, cat),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
              error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 📱 MOBILE CATEGORIES CAROUSEL WITH SETTINGS GEAR
  // =========================================================================
  Widget _buildMobileCategoriesCarousel(
    BuildContext context,
    AsyncValue<List<CategoryModel>> categoriesAsync,
    String? selectedCategoryId,
    ThemeData theme,
  ) {
    return categoriesAsync.when(
      data: (categories) {
        final sortedCategories = List<CategoryModel>.from(categories)
          ..sort((a, b) => a.orden.compareTo(b.orden));

        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: sortedCategories.length + 1,
                  itemBuilder: (context, index) {
                    final bool isAll = index == 0;
                    final String? catId = isAll ? null : sortedCategories[index - 1].id;
                    final String nombre = isAll ? 'Todos' : sortedCategories[index - 1].nombre;
                    final bool isSelected = selectedCategoryId == catId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedCategoryIdProvider.notifier).state = catId;
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFF1E2024),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF00F0FF).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            nombre,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Mobile category management bottom sheet shortcut
            InkWell(
              onTap: () => _openMobileCategoryManager(context, sortedCategories),
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2024),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Icon(Icons.settings, color: Color(0xFF00F0FF), size: 20),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 38),
      error: (err, st) => const SizedBox(height: 38),
    );
  }

  // =========================================================================
  // 📦 PRODUCTS PANEL (GRID OF PRODUCTS)
  // =========================================================================
  Widget _buildProductsPanel(
    BuildContext context,
    AsyncValue<List<ProductModel>> filteredProducts,
    String? selectedCategoryId,
    ThemeData theme,
  ) {
    final currencySymbol = ref.watch(currencySymbolProvider);

    return filteredProducts.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_bar, size: 48, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 12),
                Text(
                  'No hay productos registrados',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildAdminProductCard(context, product, currencySymbol);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
      error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }

  // Product card inside administration
  Widget _buildAdminProductCard(BuildContext context, ProductModel product, String currencySymbol) {
    String precioText = '';
    if (product.variantes.isEmpty) {
      precioText = 'Sin precio';
    } else if (product.variantes.length == 1) {
      final double precio = product.variantes.first.precioA;
      precioText = '$currencySymbol${precio.toStringAsFixed(2)}';
    } else {
      final minPrecio = product.variantes.map((v) => v.precioA).reduce((a, b) => a < b ? a : b);
      precioText = 'Desde $currencySymbol${minPrecio.toStringAsFixed(2)}';
    }

    return Opacity(
      opacity: product.disponible ? 1.0 : 0.4,
      child: Container(
        decoration: BoxDecoration(
        color: const Color(0xFF1E2024), // surface-container
        borderRadius: BorderRadius.circular(24), // Liquid extreme rounded
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / Icon
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.fotoUrl != null && product.fotoUrl!.isNotEmpty)
                    Image.network(
                      product.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderDrinkIcon(),
                    )
                  else
                    _buildPlaceholderDrinkIcon(),
                  // Top overlay for quick actions
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        // Visibility toggle
                        GestureDetector(
                          onTap: () => _toggleProductVisibility(context, product),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              product.disponible ? Icons.toggle_on : Icons.toggle_off, 
                              color: product.disponible ? const Color(0xFF00F0FF) : Colors.orangeAccent, 
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Edit action
                        GestureDetector(
                          onTap: () => _openAddEditProductDialog(context, product),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Color(0xFF00F0FF), size: 14),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Delete action
                        GestureDetector(
                          onTap: () => _confirmDeleteProduct(context, product),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.nombre,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  product.descripcion ?? 'Sin descripción',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      precioText,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF00F0FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7000FF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${product.variantes.length} Var',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD1BCFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPlaceholderDrinkIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7000FF).withOpacity(0.15),
            const Color(0xFF00F0FF).withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_bar_outlined,
          color: const Color(0xFF7000FF).withOpacity(0.4),
          size: 32,
        ),
      ),
    );
  }

  // =========================================================================
  // ⚡ CATEGORY ACTIONS & DISPATCHERS
  // =========================================================================
  Future<void> _swapCategoriesOrder(
    BuildContext context,
    CategoryModel activeCat,
    CategoryModel otherCat,
  ) async {
    final notifier = ref.read(menuAdminProvider.notifier);
    final int activeOrder = activeCat.orden;
    final int otherOrder = otherCat.orden;

    // Swap ordering numbers
    await notifier.updateCategory(activeCat.id, activeCat.nombre, otherOrder);
    await notifier.updateCategory(otherCat.id, otherCat.nombre, activeOrder);
  }

  void _openCategoryDialog(BuildContext context, CategoryModel? category) {
    final TextEditingController nameController =
        TextEditingController(text: category?.nombre ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131518),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category == null ? 'Nueva Categoría' : 'Editar Categoría',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'NOMBRE',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.liquidOnSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C0E12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: nameController,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ej. Cócteles, Botellas...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final notifier = ref.read(menuAdminProvider.notifier);
                    bool success = false;

                    if (category == null) {
                      final currentCats = ref.read(categoriesProvider).value ?? [];
                      final nextOrder = currentCats.isEmpty
                          ? 1
                          : currentCats.map((c) => c.orden).reduce((a, b) => a > b ? a : b) + 1;

                      success = await notifier.createCategory(
                        nameController.text.trim(),
                        nextOrder,
                      );
                    } else {
                      success = await notifier.updateCategory(
                        category.id,
                        nameController.text.trim(),
                        category.orden,
                      );
                    }

                    if (success && mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Guardar Categoría',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0c0e12),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // ⚡ COMPONENTE MAESTRO DE CONFIRMACIÓN (BOTTOM SHEET)
  // =========================================================================
  Future<bool?> _showBottomConfirmation({
    required BuildContext context,
    required String title,
    required String description,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1A1C20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: confirmColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: confirmColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancelar', style: GoogleFonts.inter(color: Colors.white60)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        confirmText,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: confirmColor == const Color(0xFF00F0FF) ? const Color(0xFF0c0e12) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryModel category) async {
    final bool? confirm = await _showBottomConfirmation(
      context: context,
      title: '¿Eliminar ${category.nombre}?',
      description: '¿Estás seguro de que deseas eliminar la categoría "${category.nombre}"? Esto desvinculará sus productos y no se puede deshacer.',
      confirmText: 'Eliminar',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline,
    );

    if (confirm == true) {
      ref.read(menuAdminProvider.notifier).deleteCategory(category.id);
    }
  }

  // Mobile categories management panel
  void _openMobileCategoryManager(BuildContext context, List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1C20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Administrar Categorías',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00F0FF)),
                        onPressed: () {
                          Navigator.pop(context);
                          _openCategoryDialog(context, null);
                        },
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: categories.length,
                      onReorder: (oldIndex, newIndex) {
                        setModalState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = categories.removeAt(oldIndex);
                          categories.insert(newIndex, item);

                          // Update orders in background
                          final notifier = ref.read(menuAdminProvider.notifier);
                          for (int i = 0; i < categories.length; i++) {
                            if (categories[i].orden != i + 1) {
                              notifier.updateCategory(categories[i].id, categories[i].nombre, i + 1);
                            }
                          }
                        });
                      },
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return Padding(
                          key: ValueKey(cat.id),
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Opacity(
                            opacity: cat.disponible ? 1.0 : 0.4,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF131518),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                title: Text(
                                  cat.nombre,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        cat.disponible ? Icons.toggle_on : Icons.toggle_off, 
                                        size: 16, 
                                        color: cat.disponible ? const Color(0xFF00F0FF) : Colors.orangeAccent
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _toggleCategoryVisibility(context, cat);
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF00F0FF)),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _openCategoryDialog(context, cat);
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _confirmDeleteCategory(context, cat);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_handle, color: Colors.white30, size: 24),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 🧪 PRODUCT ACTIONS & MUTATORS
  // =========================================================================
  void _confirmDeleteProduct(BuildContext context, ProductModel product) async {
    final bool? confirm = await _showBottomConfirmation(
      context: context,
      title: '¿Eliminar ${product.nombre}?',
      description: '¿Estás seguro de que deseas eliminar el producto "${product.nombre}" del catálogo?',
      confirmText: 'Eliminar',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline,
    );

    if (confirm == true) {
      ref.read(menuAdminProvider.notifier).deleteProduct(product.id);
    }
  }

  void _toggleCategoryVisibility(BuildContext context, CategoryModel category) async {
    final bool? confirm = await _showBottomConfirmation(
      context: context,
      title: category.disponible ? '¿Apagar Categoría?' : '¿Encender Categoría?',
      description: category.disponible
          ? 'Esto apagará la categoría y ocultará de forma automática (en cascada) todos sus productos en el punto de venta y Menú QR. ¿Estás seguro?'
          : 'Esto encenderá la categoría y hará visibles nuevamente todos los productos y variantes que contenga. ¿Estás seguro?',
      confirmText: category.disponible ? 'Sí, Apagar' : 'Sí, Encender',
      confirmColor: category.disponible ? Colors.orangeAccent : const Color(0xFF00F0FF),
      icon: category.disponible ? Icons.toggle_off : Icons.toggle_on,
    );

    if (confirm == true) {
      ref.read(menuAdminProvider.notifier).updateCategory(
        category.id,
        category.nombre,
        category.orden,
        disponible: !category.disponible,
      );
    }
  }

  void _toggleProductVisibility(BuildContext context, ProductModel product) async {
    final bool? confirm = await _showBottomConfirmation(
      context: context,
      title: product.disponible ? '¿Apagar Producto?' : '¿Encender Producto?',
      description: product.disponible
          ? 'Esto apagará el producto y ocultará de forma automática (en cascada) todas sus variantes en el punto de venta y Menú QR. ¿Estás seguro?'
          : 'Esto encenderá el producto y hará visibles nuevamente todas sus variantes. ¿Estás seguro?',
      confirmText: product.disponible ? 'Sí, Apagar' : 'Sí, Encender',
      confirmColor: product.disponible ? Colors.orangeAccent : const Color(0xFF00F0FF),
      icon: product.disponible ? Icons.toggle_off : Icons.toggle_on,
    );

    if (confirm == true) {
      ref.read(menuAdminProvider.notifier).updateProduct(
        product.id,
        {'disponible': !product.disponible},
      );
    }
  }

  void _openAddEditProductDialog(BuildContext context, ProductModel? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        return AddEditProductDialog(product: product);
      },
    );
  }
}

// =========================================================================
// 🚀 ADD / EDIT PRODUCT DIALOG (LIQUID MODERNIST SPECIFICATION)
// =========================================================================
class AddEditProductDialog extends ConsumerStatefulWidget {
  final ProductModel? product;

  const AddEditProductDialog({super.key, this.product});

  @override
  ConsumerState<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends ConsumerState<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedCategoryId;
  String? _fotoUrl;
  bool _isUploadingImage = false;
  bool _isDisponible = true;

  // Local list to manage variants: each item is a local helper representation
  // precios map stores: tarifaId -> precioUnitario
  final List<Map<String, dynamic>> _localVariants = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.nombre ?? '');
    _descriptionController = TextEditingController(text: widget.product?.descripcion ?? '');
    _selectedCategoryId = widget.product?.categoriaId;
    _fotoUrl = widget.product?.fotoUrl;
    _isDisponible = widget.product?.disponible ?? true;

    if (widget.product != null && widget.product!.variantes.isNotEmpty) {
      for (final variant in widget.product!.variantes) {
        final pricesMap = <String, double>{};
        for (final p in variant.precios) {
          pricesMap[p.tarifaId] = p.precioUnitario;
        }

        _localVariants.add({
          'id': variant.id,
          'nombre': variant.nombre,
          'disponible': variant.disponible,
          'precios': pricesMap,
        });
      }
    }

    // Set default selected category to currently selected POS category if creating
    if (_selectedCategoryId == null) {
      final currentSelected = ref.read(selectedCategoryIdProvider);
      if (currentSelected != null) {
        _selectedCategoryId = currentSelected;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final url = await ref.read(menuAdminProvider.notifier).uploadImage(file.path, 'productos');

      if (mounted) {
        setState(() {
          _fotoUrl = url;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _addLocalVariant(List<TarifaModel> tariffs) {
    final pricesMap = <String, double>{};
    for (final tariff in tariffs) {
      pricesMap[tariff.id] = 0.0;
    }

    setState(() {
      _localVariants.add({
        'id': null,
        'nombre': _localVariants.isEmpty ? 'Único' : '',
        'disponible': true,
        'precios': pricesMap,
      });
    });
  }

  void _removeLocalVariant(int index) {
    setState(() {
      _localVariants.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).value ?? [];
    final tariffs = ref.watch(barTarifasProvider).value ?? [];

    // Auto add default unique variant if creating and none exist
    if (_localVariants.isEmpty && tariffs.isNotEmpty) {
      _addLocalVariant(tariffs);
    }

    final viewInsets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;
    final maxModalHeight = size.height * 0.9;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxModalHeight,
      ),
      margin: EdgeInsets.only(bottom: viewInsets.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024), // Level 2 Modal
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag indicator bar (very elegant)
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Dialog Title & Close button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.product == null ? 'Registrar Producto' : 'Editar ${widget.product!.nombre}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10),

          // Form fields section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                        // Bento layout: Split basic info and Cover photo
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 550;
                            
                            final basicInputsWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOMBRE DEL PRODUCTO',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.liquidOnSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildStyledField(
                                  controller: _nameController,
                                  hintText: 'Ej. Mojito Cubano Classic',
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
                                ),
                              ],
                            );

                            final coverImageWidget = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FOTO EN PORTADA',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.liquidOnSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: _isUploadingImage ? null : _pickImage,
                                  child: Container(
                                    height: 125,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0C0E12),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                        width: 1,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                                          Image.network(_fotoUrl!, fit: BoxFit.cover)
                                        else
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate_outlined,
                                                color: Colors.white.withOpacity(0.3),
                                                size: 32,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'Elegir Imagen (WebP)',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white30,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            ],
                                          ),
                                        if (_isUploadingImage)
                                          Positioned.fill(
                                            child: Container(
                                              color: Colors.black54,
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  color: Color(0xFF00F0FF),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: basicInputsWidget),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 2, child: coverImageWidget),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  coverImageWidget,
                                  const SizedBox(height: 16),
                                  basicInputsWidget,
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'DESCRIPCIÓN',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.liquidOnSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildStyledField(
                          controller: _descriptionController,
                          hintText: 'Ej. Ron blanco, hierbabuena fresca, azúcar...',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),

                        // Category Dropdown selector
                        Text(
                          'CATEGORÍA',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.liquidOnSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C0E12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            dropdownColor: const Color(0xFF1E2024),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(border: InputBorder.none),
                            hint: Text('Selecciona una categoría...', style: TextStyle(color: Colors.white30, fontSize: 14)),
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.nombre),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategoryId = val;
                              });
                            },
                            validator: (val) => val == null ? 'La categoría es obligatoria' : null,
                          ),
                        ),



                        const SizedBox(height: 24),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),

                        // VARIANTES Y MATRIZ DE PRECIOS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'VARIANTES',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF00F0FF),
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.05,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _addLocalVariant(tariffs),
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00F0FF), size: 16),
                              label: Text(
                                'Agregar Variante',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF00F0FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_localVariants.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text(
                                'No se han configurado variantes. Agrega una para establecer precios.',
                                style: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _localVariants.length,
                            itemBuilder: (context, vIndex) {
                              final variant = _localVariants[vIndex];
                              final pricesMap = variant['precios'] as Map<String, double>;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16181C), // Contrast surface
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.04),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Variant Info Row (Name, Available toggle, Delete)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'NOMBRE DE LA VARIANTE',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: AppTheme.liquidOnSurfaceVariant,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0C0E12),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                                ),
                                                child: TextFormField(
                                                  initialValue: variant['nombre'],
                                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                                  decoration: const InputDecoration(
                                                    hintText: 'Ej. Vaso, Botella, Único...',
                                                    hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    border: InputBorder.none,
                                                  ),
                                                  onChanged: (val) {
                                                    variant['nombre'] = val.trim();
                                                  },
                                                  validator: (val) => val == null || val.trim().isEmpty
                                                      ? 'El nombre de variante es obligatorio'
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Available toggle
                                        Column(
                                          children: [
                                            Text(
                                              'DISPONIBLE',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: AppTheme.liquidOnSurfaceVariant,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Switch(
                                              value: variant['disponible'] as bool? ?? true,
                                              activeColor: const Color(0xFF00F0FF),
                                              onChanged: (val) {
                                                setState(() {
                                                  variant['disponible'] = val;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        // Delete variant if more than 1
                                        if (_localVariants.length > 1)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 14.0, left: 8.0),
                                            child: IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                              onPressed: () => _removeLocalVariant(vIndex),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    const Divider(color: Colors.white10),
                                    const SizedBox(height: 8),

                                    // Matrix Tariff Pricing Inputs
                                    Text(
                                      'MATRIZ DE PRECIOS POR TARIFA',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.liquidOnSurfaceVariant,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Display list of input boxes for each active tariff
                                    tariffs.isEmpty
                                        ? const Text(
                                            'Cargando tarifas de bar...',
                                            style: TextStyle(color: Colors.white24, fontSize: 11),
                                          )
                                        : GridView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                              maxCrossAxisExtent: 220,
                                              mainAxisSpacing: 8,
                                              crossAxisSpacing: 8,
                                              childAspectRatio: 2.2,
                                            ),
                                            itemCount: tariffs.length,
                                            itemBuilder: (context, tIndex) {
                                              final tariff = tariffs[tIndex];
                                              final double price = pricesMap[tariff.id] ?? 0.0;

                                              return Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0C0E12),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      tariff.nombre.toUpperCase(),
                                                      style: GoogleFonts.plusJakartaSans(
                                                        color: tariff.esDefault
                                                            ? const Color(0xFF00F0FF)
                                                            : Colors.white60,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 9,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Expanded(
                                                      child: TextFormField(
                                                        initialValue: price > 0 ? price.toStringAsFixed(2) : '',
                                                        style: GoogleFonts.jetBrainsMono(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                        decoration: InputDecoration(
                                                          hintText: '0.00',
                                                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.zero,
                                                          border: InputBorder.none,
                                                        ),
                                                        onChanged: (val) {
                                                          final double? pNum = double.tryParse(val);
                                                          pricesMap[tariff.id] = pNum ?? 0.0;
                                                        },
                                                        validator: (val) {
                                                          if (val == null || val.trim().isEmpty) return 'Requerido';
                                                          final double? pNum = double.tryParse(val);
                                                          if (pNum == null || pNum < 0) return 'Inválido';
                                                          return null;
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(color: Colors.white10),

              // Bottom Actions Pane
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F0FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text(
                        'Guardar Producto',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0c0e12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        validator: validator,
      ),
    );
  }

  // =========================================================================
  // 💾 SAVE MUTATION LOGIC (NESTJS SYNC BRIDGE)
  // =========================================================================
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // El estado de disponibilidad ahora se gestiona desde fuera del modal.

    if (_selectedCategoryId == null) return;
    final notifier = ref.read(menuAdminProvider.notifier);
    bool overallSuccess = false;

    // 1. Structure the variants list to match CreateVariantDto
    final List<Map<String, dynamic>> variantsPayload = [];
    for (final v in _localVariants) {
      final pricesPayload = <Map<String, dynamic>>[];
      final pricesMap = v['precios'] as Map<String, double>;

      pricesMap.forEach((tariffId, priceVal) {
        pricesPayload.add({
          'tarifa_id': tariffId,
          'precio_unitario': priceVal,
        });
      });

      variantsPayload.add({
        'nombre': v['nombre'],
        'disponible': v['disponible'],
        'precios': pricesPayload,
      });
    }

    if (widget.product == null) {
      // --- CREATE PRODUCT SCENARIO ---
      overallSuccess = await notifier.createProduct(
        nombre: _nameController.text.trim(),
        descripcion: _descriptionController.text.trim(),
        fotoUrl: _fotoUrl,
        categoriaId: _selectedCategoryId!,
        disponible: true,
        variantes: variantsPayload,
      );
    } else {
      // --- EDIT PRODUCT SCENARIO ---
      // Save product basic properties first
      final Map<String, dynamic> updates = {
        'nombre': _nameController.text.trim(),
        'descripcion': _descriptionController.text.trim(),
        'foto_url': _fotoUrl,
        'categoria_id': _selectedCategoryId,
      };

      overallSuccess = await notifier.updateProduct(widget.product!.id, updates);

      if (overallSuccess) {
        // Sync Variants:
        // A. Add or Update variants based on whether they have an ID
        final List<String> dialogVariantIds = [];

        for (final v in _localVariants) {
          final String? variantId = v['id'] as String?;
          final pricesPayload = <Map<String, dynamic>>[];
          final pricesMap = v['precios'] as Map<String, double>;

          pricesMap.forEach((tariffId, priceVal) {
            pricesPayload.add({
              'tarifa_id': tariffId,
              'precio_unitario': priceVal,
            });
          });

          final Map<String, dynamic> vPayload = {
            'nombre': v['nombre'],
            'disponible': v['disponible'],
            'precios': pricesPayload,
          };

          if (variantId == null) {
            // New variant: add it
            await notifier.addVariant(widget.product!.id, vPayload);
          } else {
            // Existing variant: update it
            await notifier.updateVariant(variantId, vPayload);
            dialogVariantIds.add(variantId);
          }
        }

        // B. Remove variants deleted in the dialog (present in db, but not in dialog list)
        for (final originalV in widget.product!.variantes) {
          if (!dialogVariantIds.contains(originalV.id)) {
            // Deleted by the user: request removal in NestJS
            await notifier.deleteVariant(originalV.id);
          }
        }
      }
    }

    if (overallSuccess && mounted) {
      Navigator.pop(context);
    }
  }
}
