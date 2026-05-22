import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/variant_model.dart';
import '../providers/catalog_provider.dart';
import '../providers/cart_provider.dart';
import '../repository/catalog_repository.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../caja/providers/caja_provider.dart';
import '../../admin/providers/bar_provider.dart';
import '../../admin/providers/tarifas_provider.dart';
import '../../admin/data/models/tarifa_model.dart';
class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCheckingOut = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(posCategoriesProvider);
    final productsAsync = ref.watch(posFilteredProductsProvider);
    final cart = ref.watch(cartProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    // Consultar reactivamente si la caja está abierta para el bloqueo preventivo
    final cajaState = ref.watch(cajaStateProvider);
    final bool isCajaAbierta = cajaState.maybeWhen(
      data: (estado) => estado.abierta,
      orElse: () => false,
    );


    // Filtrar localmente en base a la búsqueda en memoria (0ms lag)
    final filteredProducts = productsAsync.whenData((products) {
      if (_searchQuery.isEmpty) return products;
      return products
          .where((p) => p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121214), // Midnight background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth >= 900;

          if (isTablet) {
            return Row(
              children: [
                // Columna Izquierda: Catálogo y Búsqueda
                Expanded(
                  child: _buildCatalogSection(
                    context: context,
                    categoriesAsync: categoriesAsync,
                    filteredProducts: filteredProducts,
                    selectedCategoryId: selectedCategoryId,
                    theme: theme,
                  ),
                ),
                // Línea divisoria elegante
                Container(
                  width: 1,
                  color: Colors.white.withOpacity(0.05),
                ),
                // Columna Derecha: Ticket / Carrito Fijo (Tablet)
                Container(
                  width: 380,
                  color: const Color(0xFF1A1C20), // surface-container-low
                  child: _buildCartSection(context: context, cart: cart, theme: theme),
                ),
              ],
            );
          } else {
            // Layout Móvil: Catálogo + Ticket flotante deslizable
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: _buildCatalogSection(
                        context: context,
                        categoriesAsync: categoriesAsync,
                        filteredProducts: filteredProducts,
                        selectedCategoryId: selectedCategoryId,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                // Ticket Flotante Inferior (Móvil)
                if (cart.items.isNotEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _buildMobileFloatingCartButton(context: context, cart: cart, theme: theme),
                  ),
              ],
            );
          }
        },
      ),
      ),
    );
  }

  // =========================================================================
  // 📚 SECCIÓN DEL CATÁLOGO
  // =========================================================================
  Widget _buildCatalogSection({
    required BuildContext context,
    required AsyncValue<List<CategoryModel>> categoriesAsync,
    required AsyncValue<List<ProductModel>> filteredProducts,
    required String? selectedCategoryId,
    required ThemeData theme,
  }) {
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
          const SizedBox(height: 12),

          // Pestañas de Categoría (Scrollable Row)
          categoriesAsync.when(
            data: (categories) {
              final sortedCategories = List<CategoryModel>.from(categories)
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
              );
            },
            loading: () => const SizedBox(height: 38),
            error: (err, stack) => const SizedBox(height: 38),
          ),
          const SizedBox(height: 12),

          // Grilla de Productos
          Expanded(
            child: filteredProducts.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_bar, size: 48, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 12),
                        Text(
                          'No hay bebidas disponibles',
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
                  padding: EdgeInsets.only(bottom: 86.0), // Floating cart padding
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
                    return _buildProductCard(context: context, product: product, theme: theme);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F0FF),
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error al cargar catálogo: $err',
                  style: GoogleFonts.plusJakartaSans(color: Colors.redAccent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de Producto Individual (Liquid Modernist Style)
  Widget _buildProductCard({
    required BuildContext context,
    required ProductModel product,
    required ThemeData theme,
  }) {
    final cart = ref.watch(cartProvider);
    final hasDama = cart.selectedDamaId != null;
    final currencySymbol = ref.watch(currencySymbolProvider);

    // Calcular cuántos de este producto hay en el carrito
    final int quantityInCart = cart.items
        .where((item) => item.product.id == product.id)
        .fold<int>(0, (sum, item) => sum + item.quantity);
    
    // Color de acento basado en el estado (Dama o Normal)
    final accentColor = hasDama ? const Color(0xFFFF00D6) : const Color(0xFF00F0FF);

    // Calcular el precio a mostrar (si tiene variantes)
    String precioText = '';
    if (product.variantes.isEmpty) {
      precioText = 'Sin precio';
    } else if (product.variantes.length == 1) {
      final double precio = hasDama ? product.variantes.first.precioB : product.variantes.first.precioA;
      precioText = '$currencySymbol${precio.toStringAsFixed(2)}';
    } else {
      // Tiene múltiples variantes, mostrar el rango mínimo
      final minPrecio = product.variantes.map((v) => hasDama ? v.precioB : v.precioA).reduce((a, b) => a < b ? a : b);
      precioText = 'Desde $currencySymbol${minPrecio.toStringAsFixed(2)}';
    }

    return Container(
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
          // Imagen / Miniatura elegante del Trago
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
                  // Gradiente inferior
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
                  // Top overlay for quick actions
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
                          onTap: () => _handleProductAdd(product),
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
                  // Notificación Flotante (Contador Izquierda)
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

          // Contenido de la tarjeta
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

                // Precio y Variantes
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

  // Placeholder para cuando una bebida no tiene foto asignada en la DB
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
  // 🛒 SECCIÓN DE TICKET DE VENTA (CARRITO)
  // =========================================================================
  Widget _buildCartSection({
    required BuildContext context,
    required CartState cart,
    required ThemeData theme,
    BuildContext? modalContext,
  }) {
    final damasAsync = ref.watch(damasProvider);
    final cajaState = ref.watch(cajaStateProvider);
    final barState = ref.watch(currentBarProvider);
    final tarifasState = ref.watch(barTarifasProvider);
    final bool isCajaAbierta = cajaState.maybeWhen(
      data: (estado) => estado.abierta,
      orElse: () => false,
    );
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabecera del ticket compactada para optimizar espacio y evitar desperdicio arriba
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket de Venta',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (cart.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                  onPressed: () => ref.read(cartProvider.notifier).clear(),
                  tooltip: 'Limpiar ticket',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 8), 
        
        // --- SELECTOR GLOBAL DE COMPAÑÍA ---
        barState.maybeWhen(
          data: (bar) {
            if (bar.moduloDamasActivo && bar.tarifaCompaniaId != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: damasAsync.when(
                      data: (damas) {
                        // Evitar CRASH si el ID guardado no existe
                        final isDamaValid = cart.selectedDamaId != null && damas.any((d) => d.id == cart.selectedDamaId);
                        final safeSelectedDamaId = isDamaValid ? cart.selectedDamaId : null;

                        return DropdownButton<String?>(
                          isExpanded: true,
                          value: safeSelectedDamaId,
                          hint: Text('Sin Compañía (Cliente Normal)', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13)),
                          dropdownColor: const Color(0xFF1E2024),
                          icon: const Icon(Icons.people_alt_outlined, color: Colors.blueAccent, size: 20),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Sin Compañía', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13)),
                            ),
                            ...damas.map((d) => DropdownMenuItem<String?>(
                              value: d.id,
                              child: Text(d.nombre, style: GoogleFonts.plusJakartaSans(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                            )),
                          ],
                          onChanged: (val) {
                            final dama = damas.firstWhere((d) => d.id == val, orElse: () => UserModel(id: '', username: '', nombre: '', rolId: '', rolNombre: ''));
                            
                            final tarifaDefaultId = tarifasState.maybeWhen(
                              data: (tfs) => tfs.firstWhere((t) => t.esDefault, orElse: () => tfs.first).id,
                              orElse: () => '',
                            );

                            ref.read(cartProvider.notifier).setDama(
                              val,
                              val == null ? null : dama.nombre,
                              tarifaCompaniaId: bar.tarifaCompaniaId!,
                              tarifaDefaultId: tarifaDefaultId,
                            );
                          },
                        );
                      },
                      loading: () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Text('Cargando personal...', style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      error: (err, _) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Text('No se pudo cargar el personal', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
          orElse: () => const SizedBox(),
        ),
        if (!isCajaAbierta)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Turno cerrado. Abra la caja operativa antes de registrar ventas.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Lista de bebidas añadidas
        Expanded(
          child: cart.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 40, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      Text(
                        'Ticket vacío',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final List<TarifaModel> tarifasActivas = tarifasState.maybeWhen(data: (t) => t, orElse: () => []);
                    final String tDefaultId = tarifasActivas.firstWhere((t) => t.esDefault, orElse: () => TarifaModel(id: '', barId: '', nombre: '', esDefault: true, activo: true)).id;
                    final String tCompaniaId = barState.maybeWhen(data: (b) => b.tarifaCompaniaId ?? '', orElse: () => '');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (cart.selectedDamaId != null && cart.selectedDamaId!.isNotEmpty && !item.esInvitacion)
                                ? const Color(0xFFFF00D6).withOpacity(0.2)
                                : (item.esInvitacion
                                    ? Colors.amber.withOpacity(0.2)
                                    : (item.tarifaId != tDefaultId ? const Color(0xFF00F0FF).withOpacity(0.2) : Colors.white.withOpacity(0.04))),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Fila Superior: Nombre, Variante, Cantidad y Controles
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.nombre,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (item.product.variantes.length > 1) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Formato: ${item.variant.nombre}',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white54,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        '$currencySymbol${item.precioUnitario.toStringAsFixed(2)} x ${item.quantity}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: (cart.selectedDamaId != null && cart.selectedDamaId!.isNotEmpty && !item.esInvitacion)
                                              ? const Color(0xFFFF00D6)
                                              : (item.esInvitacion ? Colors.amber : const Color(0xFF00F0FF)),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Control de cantidad
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 20),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantityByIndex(index, -1);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      child: Text(
                                        '${item.quantity}',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 20),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantityByIndex(index, 1);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 8),

                            // Fila Inferior: Controles y Subtotal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Controles: Invitación o Selector de Tarifa
                                if (cart.selectedDamaId != null && cart.selectedDamaId!.isNotEmpty) ...[
                                  // Botón Invitación (Toggle)
                                  InkWell(
                                    onTap: () {
                                      ref.read(cartProvider.notifier).toggleInvitacion(
                                        index, 
                                        tarifaDefaultId: tDefaultId, 
                                        tarifaCompaniaId: tCompaniaId
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: item.esInvitacion ? Colors.amber.withOpacity(0.15) : Colors.white.withOpacity(0.02),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: item.esInvitacion ? Colors.amber.withOpacity(0.5) : Colors.white10,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.card_giftcard, size: 14, color: item.esInvitacion ? Colors.amber : Colors.white38),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Invitación',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: item.esInvitacion ? Colors.amber : Colors.white38,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Selector manual de tarifa
                                  Container(
                                    height: 30,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: item.tarifaId.isEmpty ? (tDefaultId.isEmpty ? null : tDefaultId) : item.tarifaId,
                                        dropdownColor: const Color(0xFF1E2024),
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                                        items: tarifasActivas.map((t) => DropdownMenuItem(
                                          value: t.id,
                                          child: Text(t.nombre, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF00F0FF), fontSize: 10, fontWeight: FontWeight.bold)),
                                        )).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            ref.read(cartProvider.notifier).setItemTarifa(index, val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],

                                // Subtotal
                                Text(
                                  '$currencySymbol${item.subtotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Cómputo Total y Checkout
        if (cart.items.isNotEmpty) ...[
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Métodos de pago
                Text(
                  'Método de Pago',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['EFECTIVO', 'TARJETA', 'TR/QR', 'MIXTO'].map((metodo) {
                    final bool isSel = cart.metodoPago == metodo;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: InkWell(
                          onTap: () => ref.read(cartProvider.notifier).setMetodoPago(metodo),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSel
                                  ? const LinearGradient(
                                      colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                                    )
                                  : null,
                              color: isSel ? null : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? const Color(0xFF00F0FF).withOpacity(0.3) : Colors.white10,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                metodo,
                                style: GoogleFonts.plusJakartaSans(
                                  color: isSel ? Colors.white : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Computos Totales
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL:',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$currencySymbol${cart.total.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF00F0FF),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Botón Checkout con bloqueo de Caja Cerrada
                InkWell(
                  onTap: (_isCheckingOut || !isCajaAbierta) ? null : () => _performCheckout(cart, modalContext: modalContext),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isCajaAbierta
                          ? const LinearGradient(
                              colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isCajaAbierta ? null : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: isCajaAbierta
                          ? null
                          : Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                      boxShadow: isCajaAbierta
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00F0FF).withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _isCheckingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isCajaAbierta ? 'CONFIRMAR PAGO' : 'CAJA CERRADA (ABRA TURNO)',
                              style: GoogleFonts.plusJakartaSans(
                                color: isCajaAbierta ? Colors.white : Colors.white24,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =========================================================================
  // 📱 ELEMENTOS MÓVILES (BOTÓN FLOTANTE & BOTTOM SHEET TICKET)
  // =========================================================================
  Widget _buildMobileFloatingCartButton({
    required BuildContext context,
    required CartState cart,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Consumer(
              builder: (context, ref, child) {
                final activeCart = ref.watch(cartProvider);
                return DraggableScrollableSheet(
                  initialChildSize: 0.75,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1C20),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          // Barra decoradora de deslizar
                          const SizedBox(height: 12),
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Expanded(
                            child: _buildCartSection(
                              context: context,
                              cart: activeCart,
                              theme: theme,
                              modalContext: context,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7000FF), Color(0xFF00F0FF)],
          ),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F0FF).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  '${cart.items.fold(0, (sum, item) => sum + item.quantity)} items',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Ver Ticket',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ⚡ GESTION DE INTERACCIONES Y TRANSACCIONES
  // =========================================================================

  // Manejar cuando el usuario toca el botón de añadir a un producto
  void _handleProductAdd(ProductModel product) {
    if (product.variantes.isEmpty) return;

    final cartState = ref.read(cartProvider);
    final hasGlobalDama = cartState.selectedDamaId != null && cartState.selectedDamaId!.isNotEmpty;
    
    final tarifasState = ref.read(barTarifasProvider);
    final barState = ref.read(currentBarProvider);
    
    final List<TarifaModel> tarifasActivas = tarifasState.maybeWhen(data: (t) => t, orElse: () => []);
    final String tarifaDefaultId = tarifasActivas.isEmpty ? '' : tarifasActivas.firstWhere((t) => t.esDefault, orElse: () => tarifasActivas.first).id;
    final String tarifaCompaniaId = barState.maybeWhen(data: (b) => b.tarifaCompaniaId ?? '', orElse: () => '');
    
    final targetTarifaId = hasGlobalDama ? tarifaCompaniaId : tarifaDefaultId;

    if (product.variantes.length == 1) {
      // Tiene solo una variante, agregar directamente
      final variant = product.variantes.first;
      
      double precioFinal;
      try {
        precioFinal = variant.precios.firstWhere((p) => p.tarifaId == targetTarifaId).precioUnitario;
      } catch (_) {
        precioFinal = hasGlobalDama ? variant.precioB : variant.precioA;
      }

      ref.read(cartProvider.notifier).addItem(product, variant, tarifaId: targetTarifaId, precioUnitario: precioFinal);
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
      // Tiene multiples variantes (ej: Vaso, Botella), abrir modal de selección
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
                  
                  double precio;
                  try {
                    precio = variant.precios.firstWhere((p) => p.tarifaId == targetTarifaId).precioUnitario;
                  } catch (_) {
                    precio = hasGlobalDama ? variant.precioB : variant.precioA;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(product, variant, tarifaId: targetTarifaId, precioUnitario: precio);
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
                              '$currencySymbol${precio.toStringAsFixed(2)}',
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

  // Ejecuta la venta enviando la petición POST /ventas a NestJS
  Future<void> _performCheckout(CartState cart, {BuildContext? modalContext}) async {
    debugPrint('⚡ [POS Checkout] Iniciando proceso de venta para ${cart.items.length} ítems. Método de pago: ${cart.metodoPago}');
    setState(() => _isCheckingOut = true);

    try {
      final repository = ref.read(catalogRepositoryProvider);

      await repository.checkout(
        metodoPago: cart.metodoPago == 'TR/QR' ? 'QR' : cart.metodoPago,
        items: cart.items,
      );

      debugPrint('⚡ [POS Checkout] Venta registrada con éxito en el servidor.');

      // Limpiar carrito si tiene éxito
      ref.read(cartProvider.notifier).clear();

      // Cerrar Bottom Sheet de móvil utilizando el context específico del modal de forma segura
      if (modalContext != null && modalContext.mounted) {
        try {
          if (Navigator.canPop(modalContext)) {
            debugPrint('⚡ [POS Checkout] Cerrando modal bottom sheet de móvil.');
            Navigator.pop(modalContext);
          }
        } catch (e) {
          debugPrint('⚠️ [POS Checkout] No se pudo cerrar el modal automáticamente: $e');
        }
      }

      // Éxito visual
      _showSuccessDialog();
    } catch (e, stackTrace) {
      debugPrint('❌ [POS Checkout] Error al realizar venta: $e');
      debugPrint('$stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Error en la venta: ${e.toString().replaceAll('Exception: ', '')}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.colorDanger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  // Diálogo Neon de confirmación de venta exitosa
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2024),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF00F0FF).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00F0FF).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.4), width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF00F0FF),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡VENTA REGISTRADA!',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'La transacción se ha guardado con éxito en el sistema.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7000FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Aceptar',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
