import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../data/models/auditoria_model.dart';
import '../data/repositories/auditoria_repository.dart';

final auditoriaRepositoryProvider = Provider<AuditoriaRepository?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return null;
  
  final dio = ref.watch(dioProvider);
  return AuditoriaRepository(dio);
});

final auditoriaFiltersProvider = StateProvider<Map<String, String?>>((ref) => {
  'usuarioId': null,
  'modulo': null,
  'accion': null,
  'fechaInicio': null,
  'fechaFin': null,
});

class AuditoriaState {
  final List<AuditoriaModel> logs;
  final int page;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  AuditoriaState({
    required this.logs,
    required this.page,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    this.errorMessage,
  });

  AuditoriaState copyWith({
    List<AuditoriaModel>? logs,
    int? page,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return AuditoriaState(
      logs: logs ?? this.logs,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }
}

class AuditoriaNotifier extends StateNotifier<AuditoriaState> {
  final AuditoriaRepository? _repository;
  final Map<String, String?> _filters;

  AuditoriaNotifier(this._repository, this._filters) : super(AuditoriaState(
    logs: [],
    page: 1,
    hasMore: true,
    isLoading: false,
    isLoadingMore: false,
  )) {
    loadInitial();
  }

  Future<void> loadInitial({bool silent = false}) async {
    if (_repository == null) return;
    if (!silent) {
      state = state.copyWith(isLoading: true, errorMessage: null, logs: [], page: 1, hasMore: true);
    } else {
      state = state.copyWith(errorMessage: null);
    }
    try {
      final list = await _repository.getAuditoria(
        usuarioId: _filters['usuarioId'],
        modulo: _filters['modulo'],
        accion: _filters['accion'],
        fechaInicio: _filters['fechaInicio'],
        fechaFin: _filters['fechaFin'],
        page: 1,
        limit: 20,
      );
      state = state.copyWith(
        logs: list,
        page: 1,
        isLoading: false,
        hasMore: list.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (_repository == null || state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    try {
      final nextPage = state.page + 1;
      final list = await _repository.getAuditoria(
        usuarioId: _filters['usuarioId'],
        modulo: _filters['modulo'],
        accion: _filters['accion'],
        fechaInicio: _filters['fechaInicio'],
        fechaFin: _filters['fechaFin'],
        page: nextPage,
        limit: 20,
      );
      state = state.copyWith(
        logs: [...state.logs, ...list],
        page: nextPage,
        isLoadingMore: false,
        hasMore: list.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final auditoriaListProvider = StateNotifierProvider<AuditoriaNotifier, AuditoriaState>((ref) {
  final repo = ref.watch(auditoriaRepositoryProvider);
  final filters = ref.watch(auditoriaFiltersProvider);
  return AuditoriaNotifier(repo, filters);
});
