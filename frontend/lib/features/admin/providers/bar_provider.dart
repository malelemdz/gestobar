import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/timezone_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../data/models/bar_model.dart';
import '../data/repositories/bars_repository.dart';

final barsRepositoryProvider = Provider<BarsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BarsRepository(dio);
});

final currentBarProvider = StateNotifierProvider<CurrentBarNotifier, AsyncValue<BarModel>>((ref) {
  final authState = ref.watch(authProvider);
  final repo = ref.watch(barsRepositoryProvider);
  
  String? activeBarId;
  if (authState is AuthAuthenticated) {
    activeBarId = authState.activeBarId ?? authState.user.barId;
  }
  
  return CurrentBarNotifier(
    repository: repo,
    barId: activeBarId,
  );
});

// Proveedor de la zona horaria configurada del bar activo
final barTimezoneProvider = Provider<String>((ref) {
  final barState = ref.watch(currentBarProvider);
  
  String getLocalTimezone() {
    try {
      if (tz.timeZoneDatabase.locations.isEmpty) {
        tz_data.initializeTimeZones();
      }
      return tz.local.name;
    } catch (_) {
      return 'America/La_Paz';
    }
  }

  return barState.when(
    data: (bar) => bar.timezone.isNotEmpty ? bar.timezone : getLocalTimezone(),
    loading: () => getLocalTimezone(),
    error: (_, __) => getLocalTimezone(),
  );
});

// Proveedor de offset de tiempo con el servidor
final serverTimeOffsetProvider = FutureProvider<Duration>((ref) async {
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/time');
    final serverTimeStr = response.data['serverTime'] as String;
    final serverTime = DateTime.parse(serverTimeStr).toUtc();
    final deviceTime = DateTime.now().toUtc();
    final offset = serverTime.difference(deviceTime);
    TimezoneHelper.setServerOffset(offset);
    return offset;
  } catch (e) {
    return Duration.zero;
  }
});


class CurrentBarNotifier extends StateNotifier<AsyncValue<BarModel>> {
  final BarsRepository repository;
  final String? barId;

  CurrentBarNotifier({required this.repository, this.barId}) : super(const AsyncValue.loading()) {
    if (barId != null) {
      loadBar();
    }
  }

  Future<void> loadBar() async {
    try {
      state = const AsyncValue.loading();
      final bar = await repository.getBarInfo(barId!);
      state = AsyncValue.data(bar);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateBarInfo(Map<String, dynamic> updates) async {
    if (barId == null) return false;
    
    try {
      final updatedBar = await repository.updateBar(barId!, updates);
      state = AsyncValue.data(updatedBar);
      return true;
    } catch (e, st) {
      print('Update error: $e');
      return false;
    }
  }

  Future<String?> uploadLogo(String filePath) async {
    if (barId == null) return null;
    try {
      final url = await repository.uploadImage(filePath, 'bares');
      return url;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}
