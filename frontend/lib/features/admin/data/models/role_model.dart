class PermissionModel {
  final String id;
  final String nombre;

  PermissionModel({required this.id, required this.nombre});

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class RoleModel {
  final String id;
  final String nombre;
  final String? barId;
  final List<PermissionModel> permisos;

  RoleModel({
    required this.id,
    required this.nombre,
    this.barId,
    required this.permisos,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final list = json['permisos'] as List? ?? [];
    final permissionsList = list
        .map((p) => PermissionModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return RoleModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      barId: json['bar_id'] as String?,
      permisos: permissionsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'bar_id': barId,
      'permisos': permisos.map((p) => p.toJson()).toList(),
    };
  }
}
