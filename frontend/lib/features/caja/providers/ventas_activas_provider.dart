import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../repository/caja_repository.dart';
import '../models/venta_model.dart';
import '../../../core/network/socket_service.dart';
import '../../admin/providers/bar_provider.dart';

class VentasActivasState {
  final List<VentaModel> ventas;
  final Map<String, dynamic> totales;
  final bool isLoading;
  final String? error;

  VentasActivasState({
    required this.ventas,
    required this.totales,
    this.isLoading = false,
    this.error,
  });

  factory VentasActivasState.initial() => VentasActivasState(
        ventas: [],
        totales: {'efectivo': 0, 'tarjeta': 0, 'tr_qr': 0, 'general': 0},
        isLoading: true,
      );

  VentasActivasState copyWith({
    List<VentaModel>? ventas,
    Map<String, dynamic>? totales,
    bool? isLoading,
    String? error,
  }) {
    return VentasActivasState(
      ventas: ventas ?? this.ventas,
      totales: totales ?? this.totales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VentasActivasNotifier extends StateNotifier<VentasActivasState> {
  final CajaRepository _repository;
  final SocketService _socketService;
  final String? _barId;
  
  bool _isListeningSockets = false;

  VentasActivasNotifier(this._repository, this._socketService, this._barId)
      : super(VentasActivasState.initial()) {
    if (_barId != null) {
      _loadData();
      _initSockets();
    } else {
      state = state.copyWith(isLoading: false, error: 'No hay Bar activo');
    }
  }

  Future<void> _loadData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await _repository.getActiveVentas();
      
      state = state.copyWith(
        ventas: data['ventas'] as List<VentaModel>,
        totales: data['totales'] as Map<String, dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _initSockets() {
    if (_isListeningSockets || _barId == null) return;
    
    try {
      final socket = _socketService.socket;
      final eventName = 'nueva_venta_bar_$_barId';

      socket.on(eventName, (data) {
        debugPrint('⚡ [VentasActivas] ¡Pulso recibido! Nueva venta desde el servidor');
        // Cuando alguien hace una venta, simplemente recargamos la tabla viva
        _loadData();
      });

      _isListeningSockets = true;
    } catch (e) {
      debugPrint('⚠️ No se pudo inicializar sockets de ventas: $e');
    }
  }

  @override
  void dispose() {
    if (_isListeningSockets && _barId != null) {
      try {
        _socketService.socket.off('nueva_venta_bar_$_barId');
      } catch (_) {}
    }
    super.dispose();
  }

  // Refresco manual si el usuario desliza la pantalla
  Future<void> refresh() => _loadData();
}

final ventasActivasProvider =
    StateNotifierProvider<VentasActivasNotifier, VentasActivasState>((ref) {
  final repo = ref.watch(cajaRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  final barState = ref.watch(currentBarProvider);
  
  final barId = barState.maybeWhen(
    data: (bar) => bar.id,
    orElse: () => null,
  );

  return VentasActivasNotifier(repo, socketService, barId);
});
