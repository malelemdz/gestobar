import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../pos/providers/catalog_provider.dart';
import '../../../../core/widgets/shimmer_placeholder.dart';
import 'admin_product_card.dart';

class ProductsPanel extends ConsumerWidget {
  final String searchQuery;

  const ProductsPanel({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(filteredProductsProvider);

    final filteredProducts = productsAsync.whenData((products) {
      if (searchQuery.isEmpty) return products;
      return products
          .where((p) => p.nombre.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    });

    return RefreshIndicator(
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
                  child: Text(
                    'No se encontraron productos',
                    style: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
                  ),
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.only(bottom: 86.0),
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
              return AdminProductCard(product: product);
            },
          );
        },
        loading: () {
          return GridView.builder(
            padding: const EdgeInsets.only(bottom: 86.0),
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
        error: (err, st) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: Center(
              child: Text('Error: $st', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ),
    );
  }
}
