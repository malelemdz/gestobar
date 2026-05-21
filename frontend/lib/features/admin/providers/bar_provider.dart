import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
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
