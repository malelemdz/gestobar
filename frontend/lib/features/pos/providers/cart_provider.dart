import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/variant_model.dart';

class CartItem {
  final ProductModel product;
  final VariantModel variant;
  final int quantity;
  final double precioUnitario; // Precio en el momento de añadir (precioA o precioB)

  CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.precioUnitario,
  });

  CartItem copyWith({
    ProductModel? product,
    VariantModel? variant,
    int? quantity,
    double? precioUnitario,
  }) {
    return CartItem(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
      precioUnitario: precioUnitario ?? this.precioUnitario,
    );
  }

  double get subtotal => precioUnitario * quantity;
}

class CartState {
  final List<CartItem> items;
  final String? selectedDamaId;
  final String? selectedDamaNombre;
  final String metodoPago; // 'EFECTIVO', 'TARJETA', 'QR'
  final String clienteNombre;

  CartState({
    this.items = const [],
    this.selectedDamaId,
    this.selectedDamaNombre,
    this.metodoPago = 'EFECTIVO',
    this.clienteNombre = 'Cliente General',
  });

  CartState copyWith({
    List<CartItem>? items,
    String? selectedDamaId,
    String? selectedDamaNombre,
    String? metodoPago,
    String? clienteNombre,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedDamaId: selectedDamaId ?? this.selectedDamaId,
      selectedDamaNombre: selectedDamaNombre ?? this.selectedDamaNombre,
      metodoPago: metodoPago ?? this.metodoPago,
      clienteNombre: clienteNombre ?? this.clienteNombre,
    );
  }

  double get total {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  /// Añade una variante al carrito
  void addItem(ProductModel product, VariantModel variant) {
    // Determinar precio según si hay Dama activa en la sesión del POS
    final double precio = state.selectedDamaId != null ? variant.precioB : variant.precioA;

    // Buscar si ya existe esa variante en el ticket
    final index = state.items.indexWhere((item) => item.variant.id == variant.id);

    if (index >= 0) {
      final existingItem = state.items[index];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
        precioUnitario: precio, // Asegurar coherencia
      );
      final newItems = List<CartItem>.from(state.items);
      newItems[index] = updatedItem;
      state = state.copyWith(items: newItems);
    } else {
      final newItem = CartItem(
        product: product,
        variant: variant,
        quantity: 1,
        precioUnitario: precio,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  /// Incrementa o decrementa la cantidad de una variante (-1 o +1)
  void updateQuantity(String variantId, int delta) {
    final index = state.items.indexWhere((item) => item.variant.id == variantId);
    if (index < 0) return;

    final existingItem = state.items[index];
    final newQuantity = existingItem.quantity + delta;

    if (newQuantity <= 0) {
      // Si llega a 0, eliminar del ticket
      state = state.copyWith(
        items: state.items.where((item) => item.variant.id != variantId).toList(),
      );
    } else {
      final updatedItem = existingItem.copyWith(quantity: newQuantity);
      final newItems = List<CartItem>.from(state.items);
      newItems[index] = updatedItem;
      state = state.copyWith(items: newItems);
    }
  }

  /// Asigna una Dama al ticket (y recalcula automáticamente a Precio B) o la remueve (Precio A)
  void setDama(String? id, String? nombre) {
    state = state.copyWith(
      selectedDamaId: id,
      selectedDamaNombre: nombre,
    );

    // Recalcular los precios de todo el carrito en tiempo real
    final newItems = state.items.map((item) {
      final double precio = id != null ? item.variant.precioB : item.variant.precioA;
      return item.copyWith(precioUnitario: precio);
    }).toList();

    state = state.copyWith(items: newItems);
  }

  /// Cambia el método de pago
  void setMetodoPago(String metodo) {
    state = state.copyWith(metodoPago: metodo);
  }

  /// Cambia el nombre del cliente
  void setClienteNombre(String nombre) {
    state = state.copyWith(clienteNombre: nombre);
  }

  /// Vacía el carrito
  void clear() {
    state = CartState();
  }
}

// Proveedor global del carrito
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
