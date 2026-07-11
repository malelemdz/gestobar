import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/catalog_provider.dart';
import 'product_card.dart';
import 'package:gestobar/core/widgets/shimmer_placeholder.dart';
import 'package:gestobar/core/theme/app_theme.dart';

class CatalogSection extends ConsumerStatefulWidget {
  const CatalogSection({super.key});

  @override
  ConsumerState<CatalogSection> createState() => _CatalogSectionState();
}

class _CatalogSectionState extends ConsumerState<CatalogSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 900;
    final categoriesAsync = ref.watch(posCategoriesProvider);
    final productsAsync = ref.watch(posFilteredProductsProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    final filteredProducts = productsAsync.whenData((products) {
      if (_searchQuery.isEmpty) return products;
      return products
          .where((p) => p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador Minimalista Moderno
          Container(
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
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                hintStyle: GoogleFonts.poppins(
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
          const SizedBox(height: 12),

          // Pestañas de Categoría (Scrollable Row)
          categoriesAsync.when(
            data: (categories) {
              final sortedCategories = List.from(categories)
                ..sort((a, b) => a.orden.compareTo(b.orden));

              return SizedBox(
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
                            color: isSelected ? AppTheme.liquidPrimary : const Color(0xFF1E2024),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.liquidPrimary
                                  : Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            nombre,
                            style: GoogleFonts.poppins(
                              color: isSelected ? const Color(0xFF14161A) : Colors.white.withOpacity(0.6),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 38),
            error: (err, stack) => const SizedBox(height: 38),
          ),
          const SizedBox(height: 12),

          // Grilla de Productos
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF00F0FF),
              backgroundColor: const Color(0xFF1E2024),
              onRefresh: () async {
                await Future.wait([
                  ref.refresh(categoriesProvider.future),
                  ref.refresh(productsProvider.future),
                ]).catchError((_) => []);
              },
              child: filteredProducts.when(
                data: (products) {
                  if (products.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 400,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_bar, size: 48, color: Colors.white.withOpacity(0.15)),
                              const SizedBox(height: 12),
                              Text(
                                'No hay bebidas disponibles',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.only(bottom: isTablet ? 12.0 : 86.0),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(product: product);
                    },
                  );
                },
                loading: () {
                  return GridView.builder(
                    padding: EdgeInsets.only(bottom: isTablet ? 12.0 : 86.0),
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      return const ShimmerPlaceholder(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.all(Radius.circular(24.0)),
                      );
                    },
                  );
                },
                error: (err, stack) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: 400,
                    child: Center(
                      child: Text(
                        'Error al cargar catálogo: $err',
                        style: GoogleFonts.poppins(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
