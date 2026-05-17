class UserModel {
  final String id;
  final String username;
  final String nombre;
  final String rolId;
  final String rolNombre;
  final String? barId;
  final String? fotoUrl;
  final String? celular;

  UserModel({
    required this.id,
    required this.username,
    required this.nombre,
    required this.rolId,
    required this.rolNombre,
    this.barId,
    this.fotoUrl,
    this.celular,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      rolId: json['rol_id'] as String? ?? '',
      rolNombre: json['rol_nombre'] as String? ?? '',
      barId: json['bar_id'] as String?,
      fotoUrl: json['foto_url'] as String?,
      celular: json['celular'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nombre': nombre,
      'rol_id': rolId,
      'rol_nombre': rolNombre,
      'bar_id': barId,
      'foto_url': fotoUrl,
      'celular': celular,
    };
  }
}
