import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/variant_model.dart';

class CartItem {
  final ProductModel product;
  final VariantModel variant;
  final int quantity;
  final double precioUnitario; // Precio activo (precioA, precioB)
  final String? damaId;
  final String? damaNombre;
  final bool esPrecioB;      // true para Precio B (Compañía), false para Precio A
  final bool esInvitacion;   // true si es cortesía/invitación para la Dama (Precio A, comision 0)

  CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.precioUnitario,
    this.damaId,
    this.damaNombre,
    this.esPrecioB = false,
    this.esInvitacion = false,
  });

  CartItem copyWith({
    ProductModel? product,
    VariantModel? variant,
    int? quantity,
    double? precioUnitario,
    String? damaId,
    String? damaNombre,
    bool? esPrecioB,
    bool? esInvitacion,
  }) {
    return CartItem(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      damaId: damaId != null ? (damaId.isEmpty ? null : damaId) : this.damaId,
      damaNombre: damaNombre != null ? (damaNombre.isEmpty ? null : damaNombre) : this.damaNombre,
      esPrecioB: esPrecioB ?? this.esPrecioB,
      esInvitacion: esInvitacion ?? this.esInvitacion,
    );
  }

  double get subtotal => precioUnitario * quantity;
}

class CartState {
  final List<CartItem> items;
  final String? selectedDamaId;       // Plantilla global por defecto para nuevos ítems
  final String? selectedDamaNombre;   // Plantilla global por defecto para nuevos ítems
  final String metodoPago;            // 'EFECTIVO', 'TARJETA', 'QR', 'MIXTO'
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
      selectedDamaId: selectedDamaId != null ? (selectedDamaId.isEmpty ? null : selectedDamaId) : this.selectedDamaId,
      selectedDamaNombre: selectedDamaNombre != null ? (selectedDamaNombre.isEmpty ? null : selectedDamaNombre) : this.selectedDamaNombre,
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
    // Si hay una Dama global activa, se pre-asigna como Precio B por defecto
    final bool hasGlobalDama = state.selectedDamaId != null;
    final double precio = hasGlobalDama ? variant.precioB : variant.precioA;

    // Buscamos si existe ya un ítem con las mismas características de Dama/Precio
    // para agruparlo. Si difieren (ej: uno es Normal y otro es Dama), se crean líneas separadas.
    final index = state.items.indexWhere((item) =>
        item.variant.id == variant.id &&
        item.esPrecioB == hasGlobalDama &&
        item.damaId == state.selectedDamaId &&
        item.esInvitacion == false);

    if (index >= 0) {
      final existingItem = state.items[index];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
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
        esPrecioB: hasGlobalDama,
        damaId: state.selectedDamaId,
        damaNombre: state.selectedDamaNombre,
        esInvitacion: false,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  /// Incrementa o decrementa la cantidad de un ítem por su índice en el carrito
  void updateQuantityByIndex(int index, int delta) {
    if (index < 0 || index >= state.items.length) return;

    final existingItem = state.items[index];
    final newQuantity = existingItem.quantity + delta;

    if (newQuantity <= 0) {
      // Si llega a 0, eliminar de la lista
      final newItems = List<CartItem>.from(state.items);
      newItems.removeAt(index);
      state = state.copyWith(items: newItems);
    } else {
      final updatedItem = existingItem.copyWith(quantity: newQuantity);
      final newItems = List<CartItem>.from(state.items);
      newItems[index] = updatedItem;
      state = state.copyWith(items: newItems);
    }
  }

  /// Cambia de forma atómica el modo de precio de un ítem específico del ticket
  void setItemPriceMode(int index, {required bool esPrecioB, required bool esInvitacion}) {
    if (index < 0 || index >= state.items.length) return;

    final item = state.items[index];
    double nuevoPrecio = item.variant.precioA;
    if (esPrecioB) {
      nuevoPrecio = item.variant.precioB;
    }

    // Si se pasa a Normal, se limpia la dama asociada.
    final String? newDamaId = (esPrecioB || esInvitacion) ? item.damaId : '';
    final String? newDamaNombre = (esPrecioB || esInvitacion) ? item.damaNombre : '';

    final updatedItem = item.copyWith(
      esPrecioB: esPrecioB,
      esInvitacion: esInvitacion,
      precioUnitario: nuevoPrecio,
      damaId: newDamaId,
      damaNombre: newDamaNombre,
    );

    final newItems = List<CartItem>.from(state.items);
    newItems[index] = updatedItem;
    state = state.copyWith(items: newItems);
  }

  /// Asigna una Dama y su nombre a un ítem específico del ticket
  void setItemDama(int index, String? damaId, String? damaNombre) {
    if (index < 0 || index >= state.items.length) return;

    final item = state.items[index];
    
    // Si la Dama es nula, limpiamos el modo de precio B o invitación.
    final bool esPrecioB = damaId == null ? false : item.esPrecioB;
    final bool esInvitacion = damaId == null ? false : item.esInvitacion;
    final double nuevoPrecio = esPrecioB ? item.variant.precioB : item.variant.precioA;

    final updatedItem = item.copyWith(
      damaId: damaId ?? '',
      damaNombre: damaNombre ?? '',
      esPrecioB: esPrecioB,
      esInvitacion: esInvitacion,
      precioUnitario: nuevoPrecio,
    );

    final newItems = List<CartItem>.from(state.items);
    newItems[index] = updatedItem;
    state = state.copyWith(items: newItems);
  }

  /// Asigna una Dama global por defecto (para nuevos ítems añadidos)
  void setDama(String? id, String? nombre) {
    state = state.copyWith(
      selectedDamaId: id ?? '',
      selectedDamaNombre: nombre ?? '',
    );
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
