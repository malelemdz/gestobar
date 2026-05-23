import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/providers/bar_provider.dart';
import '../models/caja_model.dart';
import '../repository/caja_repository.dart';

class CajaNotifier extends StateNotifier<AsyncValue<EstadoCajaResponse>> {
  final CajaRepository _repository;

  CajaNotifier(this._repository) : super(const AsyncValue.loading()) {
    refreshEstado();
  }

  /// Consulta el estado actual de la caja en el servidor
  Future<void> refreshEstado() async {
    state = const AsyncValue.loading();
    try {
      final estado = await _repository.getEstado();
      state = AsyncValue.data(estado);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Realiza la apertura física y lógica de la caja
  Future<void> abrirCaja(double montoInicial) async {
    state = const AsyncValue.loading();
    try {
      await _repository.apertura(montoInicial);
      await refreshEstado(); // Refrescar para cambiar la UI a estado ABIERTO
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Cierra la caja registrando el arqueo físico y retorna el resumen financiero de forma autónoma
  Future<Map<String, dynamic>> cerrarCaja() async {
    try {
      final summary = await _repository.cierre();
      await refreshEstado(); // Refrescar para cambiar la UI a estado CERRADO
      return summary;
    } catch (e) {
      await refreshEstado();
      rethrow;
    }
  }

  /// Registra un movimiento de caja chica en caliente
  Future<void> registrarMovimiento({
    required double monto,
    required String tipo,
    required String metodoPago,
    required String concepto,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.registrarMovimiento(
        monto: monto,
        tipo: tipo,
        metodoPago: metodoPago,
        concepto: concepto,
      );
      await refreshEstado(); // Refrescar para repintar las Bento Cards y la bitácora
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// Proveedor reactivo del estado de caja activo
final cajaStateProvider =
    StateNotifierProvider<CajaNotifier, AsyncValue<EstadoCajaResponse>>((ref) {
  final repository = ref.watch(cajaRepositoryProvider);
  return CajaNotifier(repository);
});

// Proveedor del historial completo de turnos cerrados
final cajaHistoryProvider = FutureProvider<List<CajaModel>>((ref) async {
  return ref.watch(cajaRepositoryProvider).getHistory();
});

// Proveedor del símbolo de moneda del bar activo (Por defecto 'Bs' según el bar semilla)
final currencySymbolProvider = Provider<String>((ref) {
  final barState = ref.watch(currentBarProvider);
  return barState.when(
    data: (bar) => bar.monedaSimbolo,
    loading: () => 'Bs',
    error: (_, __) => 'Bs',
  );
});

// Proveedor del código ISO de moneda del bar activo
final currencyIsoProvider = Provider<String>((ref) {
  final barState = ref.watch(currentBarProvider);
  return barState.when(
    data: (bar) => bar.monedaIso,
    loading: () => 'BOB',
    error: (_, __) => 'BOB',
  );
});
