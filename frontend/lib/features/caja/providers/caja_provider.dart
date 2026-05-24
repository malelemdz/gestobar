import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../admin/providers/bar_provider.dart';
import '../models/caja_model.dart';
import '../repository/caja_repository.dart';
import '../../../core/network/socket_service.dart';

class CajaNotifier extends StateNotifier<AsyncValue<EstadoCajaResponse>> {
  final CajaRepository _repository;
  final SocketService _socketService;
  final String? _barId;
  bool _isListeningSockets = false;

  CajaNotifier(this._repository, this._socketService, this._barId) : super(const AsyncValue.loading()) {
    refreshEstado();
    if (_barId != null) {
      _initSockets();
    }
  }

  Future<void> _initSockets() async {
    if (_isListeningSockets || _barId == null) return;
    try {
      final socket = await _socketService.connect();
      
      // Escuchar tanto nuevas ventas como nuevos movimientos manuales en tiempo real
      socket.on('nueva_venta_bar_$_barId', (data) {
        debugPrint('⚡ [CajaNotifier] ¡Pulso de venta recibido! Refrescando balance...');
        refreshEstado(silent: true);
      });

      socket.on('nuevo_movimiento_bar_$_barId', (data) {
        debugPrint('⚡ [CajaNotifier] ¡Pulso de caja-movimiento recibido! Refrescando balance...');
        refreshEstado(silent: true);
      });

      _isListeningSockets = true;
    } catch (e) {
      debugPrint('⚠️ No se pudieron inicializar sockets en CajaNotifier: $e');
    }
  }

  /// Consulta el estado actual de la caja en el servidor
  Future<void> refreshEstado({bool silent = false}) async {
    if (!silent) {
      state = const AsyncValue.loading();
    }
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

  @override
  void dispose() {
    if (_isListeningSockets && _barId != null) {
      try {
        _socketService.socket?.off('nueva_venta_bar_$_barId');
        _socketService.socket?.off('nuevo_movimiento_bar_$_barId');
      } catch (_) {}
    }
    super.dispose();
  }
}

// Proveedor reactivo del estado de caja activo
final cajaStateProvider =
    StateNotifierProvider<CajaNotifier, AsyncValue<EstadoCajaResponse>>((ref) {
  final repository = ref.watch(cajaRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  final barState = ref.watch(currentBarProvider);
  
  final barId = barState.maybeWhen(
    data: (bar) => bar.id,
    orElse: () => null,
  );

  return CajaNotifier(repository, socketService, barId);
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
