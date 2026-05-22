import '../../../features/auth/models/user_model.dart';
import '../hive_entities/user_hive.dart';

extension UserHiveMapper on UserHive {
  UserModel toDomain() {
    return UserModel(
      id: id,
      username: username,
      nombre: nombre,
      rolId: rolId,
      rolNombre: rolNombre,
      barId: barId,
      fotoUrl: fotoUrl,
      celular: celular,
    );
  }
}

extension UserModelMapper on UserModel {
  UserHive toHive() {
    return UserHive(
      id: id,
      username: username,
      nombre: nombre,
      rolId: rolId,
      rolNombre: rolNombre,
      barId: barId,
      fotoUrl: fotoUrl,
      celular: celular,
    );
  }
}
