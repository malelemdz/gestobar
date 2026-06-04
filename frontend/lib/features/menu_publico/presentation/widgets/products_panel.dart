import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../pos/providers/catalog_provider.dart';
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
            return AdminProductCard(product: product);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
      error: (err, st) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
    );
  }
}
