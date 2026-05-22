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

final auditoriaListProvider = FutureProvider<List<AuditoriaModel>>((ref) async {
  final repo = ref.watch(auditoriaRepositoryProvider);
  if (repo == null) return [];
  
  final filters = ref.watch(auditoriaFiltersProvider);
  return repo.getAuditoria(
    usuarioId: filters['usuarioId'],
    modulo: filters['modulo'],
    accion: filters['accion'],
    fechaInicio: filters['fechaInicio'],
    fechaFin: filters['fechaFin'],
  );
});
