import 'package:hive/hive.dart';

part 'category_hive.g.dart';

@HiveType(typeId: 0)
class CategoryHive extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String nombre;

  @HiveField(2)
  late int orden;

  @HiveField(3)
  late bool disponible;
}
