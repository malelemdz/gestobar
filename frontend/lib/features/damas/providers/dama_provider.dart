import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class DamaComisionesState {
  final bool isLoading;
  final String? error;
  final double comisionesTotales;
  final int totalInvitaciones;
  final String moneda;
  final List<dynamic> historial;

  DamaComisionesState({
    this.isLoading = false,
    this.error,
    this.comisionesTotales = 0.0,
    this.totalInvitaciones = 0,
    this.moneda = 'Bs',
    this.historial = const [],
  });

  DamaComisionesState copyWith({
    bool? isLoading,
    String? error,
    double? comisionesTotales,
    int? totalInvitaciones,
    String? moneda,
    List<dynamic>? historial,
  }) {
    return DamaComisionesState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      comisionesTotales: comisionesTotales ?? this.comisionesTotales,
      totalInvitaciones: totalInvitaciones ?? this.totalInvitaciones,
      moneda: moneda ?? this.moneda,
      historial: historial ?? this.historial,
    );
  }
}

class DamaComisionesNotifier extends StateNotifier<DamaComisionesState> {
  final Ref ref;

  DamaComisionesNotifier(this.ref) : super(DamaComisionesState()) {
    loadComisiones();
  }

  Future<void> loadComisiones({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/ventas/comisiones');
      final data = response.data as Map<String, dynamic>;

      state = DamaComisionesState(
        isLoading: false,
        comisionesTotales: (data['comisiones_totales'] as num?)?.toDouble() ?? 0.0,
        totalInvitaciones: (data['total_invitaciones'] as num?)?.toInt() ?? 0,
        moneda: data['moneda']?.toString() ?? 'Bs',
        historial: data['historial'] as List<dynamic>? ?? [],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final damaComisionesProvider = StateNotifierProvider<DamaComisionesNotifier, DamaComisionesState>((ref) {
  return DamaComisionesNotifier(ref);
});

class DamaHistorialDiarioState {
  final bool isLoading;
  final String? error;
  final List<dynamic> historialDiario;

  DamaHistorialDiarioState({
    this.isLoading = false,
    this.error,
    this.historialDiario = const [],
  });

  DamaHistorialDiarioState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? historialDiario,
  }) {
    return DamaHistorialDiarioState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      historialDiario: historialDiario ?? this.historialDiario,
    );
  }
}

class DamaHistorialDiarioNotifier extends StateNotifier<DamaHistorialDiarioState> {
  final Ref ref;

  DamaHistorialDiarioNotifier(this.ref) : super(DamaHistorialDiarioState()) {
    loadHistorialDiario();
  }

  Future<void> loadHistorialDiario({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/ventas/comisiones/historial-diario');
      final data = response.data as List<dynamic>;

      state = DamaHistorialDiarioState(
        isLoading: false,
        historialDiario: data,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final damaHistorialDiarioProvider =
    StateNotifierProvider<DamaHistorialDiarioNotifier, DamaHistorialDiarioState>((ref) {
  return DamaHistorialDiarioNotifier(ref);
});
