import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../data/models/tarifa_model.dart';
import '../data/repositories/tarifas_repository.dart';
import 'bar_provider.dart';

final tarifasRepositoryProvider = Provider<TarifasRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TarifasRepository(dio);
});

final barTarifasProvider = FutureProvider<List<TarifaModel>>((ref) async {
  final barState = ref.watch(currentBarProvider);
  
  return barState.when(
    data: (bar) async {
      final repo = ref.read(tarifasRepositoryProvider);
      return await repo.getTarifas(bar.id);
    },
    loading: () => <TarifaModel>[],
    error: (err, st) {
      debugPrint('Error al cargar tarifas en provider: $err');
      return <TarifaModel>[];
    },
  );
});
