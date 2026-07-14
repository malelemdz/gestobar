import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'hive_entities/category_hive.dart';
import 'hive_entities/product_hive.dart';
import 'hive_entities/sync_queue_hive.dart';
import 'hive_entities/user_hive.dart';
import '../network/dio_client.dart';
import 'sync_worker.dart';

// Provider para mantener vivo el Worker de Sincronización
final syncWorkerProvider = Provider<SyncWorker>((ref) {
  final dio = ref.watch(dioProvider);
  return SyncWorker(dio);
});

Future<void> initHive() async {
  await Hive.initFlutter();
  
  // Registrar adaptadores binarios
  Hive.registerAdapter(CategoryHiveAdapter());
  Hive.registerAdapter(ProductHiveAdapter());
  Hive.registerAdapter(VariantHiveAdapter());
  Hive.registerAdapter(VariantPriceHiveAdapter());
  Hive.registerAdapter(SyncQueueTaskHiveAdapter());
  Hive.registerAdapter(UserHiveAdapter());
  
  // Control de versiones de caché local
  try {
    final metadataBox = await Hive.openBox<String>('app_metadata');
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final lastRunVersion = metadataBox.get('last_run_version');

    if (lastRunVersion != null && lastRunVersion != currentVersion) {
      // Eliminar archivos físicos de base de datos Hive de caché obsoleta
      await Hive.deleteBoxFromDisk('categories');
      await Hive.deleteBoxFromDisk('products');
      await Hive.deleteBoxFromDisk('users');
      // Nota: sync_queue no se elimina para evitar perder transacciones locales sin sincronizar
    }

    await metadataBox.put('last_run_version', currentVersion);
    await metadataBox.close();
  } catch (e) {
    // Silenciar error para no interrumpir el arranque si falla package_info
  }

  // Cargar colecciones en RAM
  await Hive.openBox<CategoryHive>('categories');
  await Hive.openBox<ProductHive>('products');
  await Hive.openBox<SyncQueueTaskHive>('sync_queue');
  await Hive.openBox<UserHive>('users');
}
