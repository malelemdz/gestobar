import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'entities/category_entity.dart';
import 'entities/product_entity.dart';
import 'entities/sync_queue_entity.dart';

// Este provider inyectará la conexión a la base de datos local en toda la App
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar no ha sido inicializado en el main.dart');
});

// Función de arranque para abrir/crear la BD en el almacenamiento físico
Future<Isar> initIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      CategoryIsarSchema,
      ProductIsarSchema,
      SyncQueueTaskIsarSchema,
    ],
    directory: dir.path,
    inspector: true, // Permite debuguear la BD con la app conectada
  );
  return isar;
}
