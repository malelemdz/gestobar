class UserModel {
  final String id;
  final String username;
  final String nombre;
  final String apellido;
  final String rolId;
  final String rolNombre;
  final String? barId;
  final String? fotoUrl;
  final String? celular;
  final String? identificacion;
  final String? nacionalidad;
  final String? direccion;
  final String? genero;
  final bool estado;

  UserModel({
    required this.id,
    required this.username,
    required this.nombre,
    this.apellido = '',
    required this.rolId,
    required this.rolNombre,
    this.barId,
    this.fotoUrl,
    this.celular,
    this.identificacion,
    this.nacionalidad,
    this.direccion,
    this.genero,
    this.estado = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String rId = json['rol_id'] as String? ?? '';
    String rNombre = json['rol_nombre'] as String? ?? '';

    // Soporte para payloads con la relación 'rol' anidada
    if (json['rol'] != null && json['rol'] is Map) {
      final rolMap = json['rol'] as Map<String, dynamic>;
      if (rId.isEmpty) rId = rolMap['id'] as String? ?? '';
      if (rNombre.isEmpty) rNombre = rolMap['nombre'] as String? ?? '';
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      rolId: rId,
      rolNombre: rNombre,
      barId: json['bar_id'] as String?,
      fotoUrl: json['foto_url'] as String?,
      celular: json['celular'] as String?,
      identificacion: json['identificacion'] as String?,
      nacionalidad: json['nacionalidad'] as String?,
      direccion: json['direccion'] as String?,
      genero: json['genero'] as String?,
      estado: json['estado'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nombre': nombre,
      'apellido': apellido,
      'rol_id': rolId,
      'rol_nombre': rolNombre,
      'bar_id': barId,
      'foto_url': fotoUrl,
      'celular': celular,
      'identificacion': identificacion,
      'nacionalidad': nacionalidad,
      'direccion': direccion,
      'genero': genero,
      'estado': estado,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? nombre,
    String? apellido,
    String? rolId,
    String? rolNombre,
    String? barId,
    String? fotoUrl,
    String? celular,
    String? identificacion,
    String? nacionalidad,
    String? direccion,
    String? genero,
    bool? estado,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      rolId: rolId ?? this.rolId,
      rolNombre: rolNombre ?? this.rolNombre,
      barId: barId ?? this.barId,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      celular: celular ?? this.celular,
      identificacion: identificacion ?? this.identificacion,
      nacionalidad: nacionalidad ?? this.nacionalidad,
      direccion: direccion ?? this.direccion,
      genero: genero ?? this.genero,
      estado: estado ?? this.estado,
    );
  }
}

