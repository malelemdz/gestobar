import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/widgets/drink_placeholder.dart';
import '../../../pos/models/product_model.dart';
import '../../../caja/providers/caja_provider.dart';
import '../../../admin/providers/menu_admin_provider.dart';
import '../dialogs/add_edit_product_dialog.dart';
import '../dialogs/bottom_confirmation_sheet.dart';

class AdminProductCard extends ConsumerWidget {
  final ProductModel product;

  const AdminProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);

    String precioText = '';
    if (product.variantes.isEmpty) {
      precioText = 'Sin precio';
    } else if (product.variantes.length == 1) {
      final double precio = product.variantes.first.precioA;
      precioText = '$currencySymbol${CurrencyHelper.formatAmount(precio, currencyIso)}';
    } else {
      final minPrecio = product.variantes.map((v) => v.precioA).reduce((a, b) => a < b ? a : b);
      precioText = 'Desde $currencySymbol${CurrencyHelper.formatAmount(minPrecio, currencyIso)}';
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
                        ApiConstants.resolveImageUrl(product.fotoUrl)!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const DrinkPlaceholder(size: 32),
                      )
                    else
                      const DrinkPlaceholder(size: 32),
                    // Top overlay for quick actions
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          // Visibility toggle
                          GestureDetector(
                            onTap: () => _toggleProductVisibility(context, ref, product),
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
                            onTap: () => _confirmDeleteProduct(context, ref, product),
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

  void _confirmDeleteProduct(BuildContext context, WidgetRef ref, ProductModel product) async {
    final bool? confirm = await BottomConfirmationSheet.show(
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

  void _toggleProductVisibility(BuildContext context, WidgetRef ref, ProductModel product) async {
    final bool? confirm = await BottomConfirmationSheet.show(
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
