import 'package:hive/hive.dart';

part 'user_hive.g.dart';

@HiveType(typeId: 5)
class UserHive extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String nombre;

  @HiveField(3)
  final String rolId;

  @HiveField(4)
  final String rolNombre;

  @HiveField(5)
  final String? barId;

  @HiveField(6)
  final String? fotoUrl;

  @HiveField(7)
  final String? celular;

  UserHive({
    required this.id,
    required this.username,
    required this.nombre,
    required this.rolId,
    required this.rolNombre,
    this.barId,
    this.fotoUrl,
    this.celular,
  });
}
