import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/variant_model.dart';

class CartItem {
  final ProductModel product;
  final VariantModel variant;
  final int quantity;
  final double precioUnitario; // Precio calculado en base a la tarifaId
  final String? damaId;
  final String? damaNombre;
  final String tarifaId;     // ID de la tarifa aplicada a este ítem
  final bool esInvitacion;   // true si es invitación para la Dama (aplica Tarifa Default)

  CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.precioUnitario,
    required this.tarifaId,
    this.damaId,
    this.damaNombre,
    this.esInvitacion = false,
  });

  CartItem copyWith({
    ProductModel? product,
    VariantModel? variant,
    int? quantity,
    double? precioUnitario,
    String? damaId,
    String? damaNombre,
    String? tarifaId,
    bool? esInvitacion,
  }) {
    return CartItem(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      damaId: damaId != null ? (damaId.isEmpty ? null : damaId) : this.damaId,
      damaNombre: damaNombre != null ? (damaNombre.isEmpty ? null : damaNombre) : this.damaNombre,
      tarifaId: tarifaId ?? this.tarifaId,
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
  void addItem(ProductModel product, VariantModel variant, {required String tarifaId, required double precioUnitario}) {
    // Buscamos si existe ya un ítem idéntico (misma variante, misma tarifa, misma dama, mismo estado de invitación)
    final index = state.items.indexWhere((item) =>
        item.variant.id == variant.id &&
        item.tarifaId == tarifaId &&
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
        precioUnitario: precioUnitario,
        tarifaId: tarifaId,
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

  /// Alterna el estado de "Invitación" de un ítem (Toggle)
  void toggleInvitacion(int index, {required String tarifaDefaultId, required String tarifaCompaniaId}) {
    if (index < 0 || index >= state.items.length) return;
    
    final item = state.items[index];
    final bool newEsInvitacion = !item.esInvitacion;
    
    // Si es invitación -> Tarifa por defecto. Si NO es invitación -> Tarifa de Compañía
    final targetTarifaId = newEsInvitacion ? tarifaDefaultId : tarifaCompaniaId;
    
    // Validar el UUID de la tarifa. Si es inválido/vacío, resolver dinámicamente desde la variante
    final String resolvedTarifaId = targetTarifaId.isNotEmpty && RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(targetTarifaId)
        ? targetTarifaId
        : (newEsInvitacion
            ? item.variant.precios.firstWhere((p) => p.esDefault, orElse: () => item.variant.precios.first).tarifaId
            : item.variant.precios.firstWhere((p) => !p.esDefault, orElse: () => item.variant.precios.first).tarifaId);

    double nuevoPrecio;
    try {
      nuevoPrecio = item.variant.precios.firstWhere((p) => p.tarifaId == resolvedTarifaId).precioUnitario;
    } catch (_) {
      nuevoPrecio = newEsInvitacion ? item.variant.precioA : item.variant.precioB;
    }

    final updatedItem = item.copyWith(
      esInvitacion: newEsInvitacion,
      tarifaId: resolvedTarifaId,
      precioUnitario: nuevoPrecio,
    );

    final newItems = List<CartItem>.from(state.items);
    newItems[index] = updatedItem;
    state = state.copyWith(items: newItems);
  }

  /// Cambia manualmente la tarifa de un ítem (Solo aplicable cuando NO hay Dama en el ticket)
  void setItemTarifa(int index, String newTarifaId) {
    if (index < 0 || index >= state.items.length) return;
    
    final item = state.items[index];
    double nuevoPrecio;
    try {
      nuevoPrecio = item.variant.precios.firstWhere((p) => p.tarifaId == newTarifaId).precioUnitario;
    } catch (_) {
      nuevoPrecio = item.variant.precioA;
    }

    final updatedItem = item.copyWith(
      tarifaId: newTarifaId,
      precioUnitario: nuevoPrecio,
    );

    final newItems = List<CartItem>.from(state.items);
    newItems[index] = updatedItem;
    state = state.copyWith(items: newItems);
  }

  /// Asigna una Dama global por defecto (para nuevos ítems añadidos) y re-calcula toda la cuenta
  void setDama(String? id, String? nombre, {required String tarifaCompaniaId, required String tarifaDefaultId}) {
    final bool hasGlobalDama = id != null && id.isNotEmpty;

    final newItems = state.items.map((item) {
      if (item.esInvitacion) {
        // Si ya era una invitación explícita, se mantiene a precio default pero actualizamos el ID de la dama
        return item.copyWith(damaId: id ?? '', damaNombre: nombre ?? '');
      }

      final targetTarifaId = hasGlobalDama ? tarifaCompaniaId : tarifaDefaultId;
      
      // Validar el UUID de la tarifa. Si es inválido/vacío, resolver dinámicamente desde la variante
      final String resolvedTarifaId = targetTarifaId.isNotEmpty && RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(targetTarifaId)
          ? targetTarifaId
          : (hasGlobalDama
              ? item.variant.precios.firstWhere((p) => !p.esDefault, orElse: () => item.variant.precios.first).tarifaId
              : item.variant.precios.firstWhere((p) => p.esDefault, orElse: () => item.variant.precios.first).tarifaId);

      double nuevoPrecio;
      try {
        nuevoPrecio = item.variant.precios.firstWhere((p) => p.tarifaId == resolvedTarifaId).precioUnitario;
      } catch (_) {
        nuevoPrecio = hasGlobalDama ? item.variant.precioB : item.variant.precioA;
      }

      return item.copyWith(
        damaId: id ?? '',
        damaNombre: nombre ?? '',
        tarifaId: resolvedTarifaId,
        precioUnitario: nuevoPrecio,
        esInvitacion: false, // Resetear bandera de invitación si quitamos dama
      );
    }).toList();

    state = state.copyWith(
      selectedDamaId: id ?? '',
      selectedDamaNombre: nombre ?? '',
      items: newItems,
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
