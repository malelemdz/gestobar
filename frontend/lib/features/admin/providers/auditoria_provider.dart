import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/socket_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../../auth/models/user_model.dart';
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
  final SocketService _socketService;
  final String? _barId;
  bool _isListening = false;

  AuditoriaNotifier(
    this._repository,
    this._filters,
    this._socketService,
    this._barId,
  ) : super(AuditoriaState(
          logs: [],
          page: 1,
          hasMore: true,
          isLoading: false,
          isLoadingMore: false,
        )) {
    loadInitial();
    _initSocket();
  }

  Future<void> _initSocket() async {
    if (_isListening || _barId == null) return;
    try {
      final socket = await _socketService.connect();
      socket.on('nuevo_log_bar_$_barId', (data) {
        if (data != null) {
          try {
            final newLog = AuditoriaModel.fromJson(Map<String, dynamic>.from(data));
            if (_matchesFilters(newLog)) {
              state = state.copyWith(
                logs: [newLog, ...state.logs],
              );
            }
          } catch (_) {}
        }
      });
      _isListening = true;
    } catch (_) {}
  }

  bool _matchesFilters(AuditoriaModel log) {
    if (_filters['usuarioId'] != null && log.usuarioId != _filters['usuarioId']) {
      return false;
    }
    if (_filters['modulo'] != null && log.modulo != _filters['modulo']) {
      return false;
    }
    if (_filters['accion'] != null && log.accion != _filters['accion']) {
      return false;
    }
    if (_filters['fechaInicio'] != null && _filters['fechaFin'] != null) {
      try {
        final start = DateTime.parse(_filters['fechaInicio']!);
        final end = DateTime.parse(_filters['fechaFin']!).add(const Duration(days: 1));
        if (log.fecha.isBefore(start) || log.fecha.isAfter(end)) {
          return false;
        }
      } catch (_) {}
    }
    return true;
  }

  @override
  void dispose() {
    if (_isListening && _barId != null) {
      _socketService.socket?.off('nuevo_log_bar_$_barId');
    }
    super.dispose();
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
  final socketService = ref.watch(socketServiceProvider);

  final authState = ref.watch(authProvider);
  String? barId;
  if (authState is AuthAuthenticated) {
    barId = authState.activeBarId ?? authState.user.barId;
  }

  return AuditoriaNotifier(repo, filters, socketService, barId);
});

// Providers for global/superadmin audit view
final superAuditoriaFiltersProvider = StateProvider<Map<String, String?>>((ref) => {
  'barId': null,
  'usuarioId': null,
  'modulo': null,
  'accion': null,
  'fechaInicio': null,
  'fechaFin': null,
});

final superAuditoriaListProvider = StateNotifierProvider<AuditoriaNotifier, AuditoriaState>((ref) {
  final repo = ref.watch(auditoriaRepositoryProvider);
  final filters = ref.watch(superAuditoriaFiltersProvider);
  final socketService = ref.watch(socketServiceProvider);

  final barId = filters['barId'];
  return AuditoriaNotifier(repo, filters, socketService, barId);
});

final superStaffListProvider = FutureProvider<List<UserModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users');
  final List data = response.data ?? [];
  return data.map((json) => UserModel.fromJson(json)).toList();
});
