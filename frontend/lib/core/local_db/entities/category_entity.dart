import 'package:isar/isar.dart';

part 'category_entity.g.dart';

@collection
class CategoryIsar {
  Id id = Isar.autoIncrement; // Isar internal ID

  @Index(unique: true, replace: true)
  late String backendId; // PostgreSQL UUID

  late String nombre;
  late int orden;
  late bool disponible;
}
