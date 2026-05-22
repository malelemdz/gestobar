import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_entities/category_hive.dart';
import 'hive_entities/product_hive.dart';
import 'hive_entities/sync_queue_hive.dart';
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
  
  // Cargar colecciones en RAM
  await Hive.openBox<CategoryHive>('categories');
  await Hive.openBox<ProductHive>('products');
  await Hive.openBox<SyncQueueTaskHive>('sync_queue');
}
