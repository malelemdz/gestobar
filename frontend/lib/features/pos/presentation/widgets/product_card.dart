import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../../admin/providers/bar_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/widgets/drink_placeholder.dart';
import '../../../caja/providers/caja_provider.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({
    super.key,
    required this.product,
  });

  void _handleProductAdd(BuildContext context, WidgetRef ref) {
    if (product.variantes.isEmpty) return;

    final cartState = ref.read(cartProvider);
    final hasGlobalDama = cartState.selectedDamaId != null && cartState.selectedDamaId!.isNotEmpty;

    final barState = ref.read(currentBarProvider);
    final bool splitSameVariants = barState.maybeWhen(
      data: (bar) => bar.moduloDamasActivo && hasGlobalDama,
      orElse: () => false,
    );

    if (product.variantes.length == 1) {
      final variant = product.variantes.first;
      final activePrice = hasGlobalDama
          ? variant.precios.firstWhere((p) => !p.esDefault, orElse: () => variant.precios.first)
          : variant.precios.firstWhere((p) => p.esDefault, orElse: () => variant.precios.first);
          
      final targetTarifaId = activePrice.tarifaId;
      final precioFinal = activePrice.precioUnitario;

      ref.read(cartProvider.notifier).addItem(
        product,
        variant,
        tarifaId: targetTarifaId,
        precioUnitario: precioFinal,
        splitSameVariants: splitSameVariants,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ ${product.nombre} añadido al ticket.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: const Color(0xFF7000FF),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E2024),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Seleccionar formato de bebida',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.nombre,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF00F0FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                ...product.variantes.map((variant) {
                  final currencySymbol = ref.read(currencySymbolProvider);
                  final currencyIso = ref.read(currencyIsoProvider);
                  
                  final activePrice = hasGlobalDama
                      ? variant.precios.firstWhere((p) => !p.esDefault, orElse: () => variant.precios.first)
                      : variant.precios.firstWhere((p) => p.esDefault, orElse: () => variant.precios.first);
                      
                  final variantTarifaId = activePrice.tarifaId;
                  final precio = activePrice.precioUnitario;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(
                          product,
                          variant,
                          tarifaId: variantTarifaId,
                          precioUnitario: precio,
                          splitSameVariants: splitSameVariants,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✓ ${product.nombre} (${variant.nombre}) añadido.',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white),
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: const Color(0xFF7000FF),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              variant.nombre,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '$currencySymbol${CurrencyHelper.formatAmount(precio, currencyIso)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: hasGlobalDama ? const Color(0xFFFF00D6) : const Color(0xFF00F0FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final hasDama = cart.selectedDamaId != null;
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyIso = ref.watch(currencyIsoProvider);

    final int quantityInCart = cart.items
        .where((item) => item.product.id == product.id)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    
    final accentColor = hasDama ? const Color(0xFFFF00D6) : const Color(0xFF00F0FF);

    String precioText = '';
    if (product.variantes.isEmpty) {
      precioText = 'Sin precio';
    } else if (product.variantes.length == 1) {
      final double precio = hasDama ? product.variantes.first.precioB : product.variantes.first.precioA;
      precioText = '$currencySymbol${CurrencyHelper.formatAmount(precio, currencyIso)}';
    } else {
      final minPrecio = product.variantes.map((v) => hasDama ? v.precioB : v.precioA).reduce((a, b) => a < b ? a : b);
      precioText = 'Desde $currencySymbol${CurrencyHelper.formatAmount(minPrecio, currencyIso)}';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0xDD121214)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        if (quantityInCart > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, color: accentColor, size: 14),
                          ),
                          const SizedBox(width: 4),
                        ],
                        GestureDetector(
                          onTap: () => _handleProductAdd(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF00F0FF), size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (quantityInCart > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$quantityInCart',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
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
                  product.descripcion != null && product.descripcion!.isNotEmpty 
                      ? product.descripcion! 
                      : 'Sin descripción',
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
                        color: hasDama ? const Color(0xFFFF00D6) : const Color(0xFF00F0FF),
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
    );
  }
}
