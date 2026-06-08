import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/socket_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../data/models/auditoria_model.dart';
import '../data/repositories/auditoria_repository.dart';
import 'auditoria_provider.dart'; // To reuse auditoriaRepositoryProvider

class RecentAuditoriaNotifier extends StateNotifier<AsyncValue<List<AuditoriaModel>>> {
  final AuditoriaRepository? _repository;
  final SocketService _socketService;
  final String? _barId;
  bool _isListening = false;

  RecentAuditoriaNotifier(this._repository, this._socketService, this._barId)
      : super(const AsyncValue.loading()) {
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
            state.whenData((logs) {
              final newLogs = [newLog, ...logs];
              if (newLogs.length > 10) newLogs.removeLast();
              state = AsyncValue.data(newLogs);
            });
          } catch (_) {}
        }
      });
      _isListening = true;
    } catch (_) {}
  }

  Future<void> loadInitial() async {
    if (_repository == null) {
      state = const AsyncValue.error('Repositorio no disponible', StackTrace.empty);
      return;
    }
    try {
      final list = await _repository.getAuditoria(page: 1, limit: 10);
      state = AsyncValue.data(list.take(10).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    if (_isListening && _barId != null) {
      _socketService.socket?.off('nuevo_log_bar_$_barId');
    }
    super.dispose();
  }
}

final recentAuditoriaProvider = StateNotifierProvider<RecentAuditoriaNotifier, AsyncValue<List<AuditoriaModel>>>((ref) {
  final repo = ref.watch(auditoriaRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);

  final authState = ref.watch(authProvider);
  String? barId;
  if (authState is AuthAuthenticated) {
    barId = authState.activeBarId ?? authState.user.barId;
  }

  return RecentAuditoriaNotifier(repo, socketService, barId);
});
