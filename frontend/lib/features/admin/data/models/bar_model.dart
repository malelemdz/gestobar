import '../../../../core/utils/currency_helper.dart';

class BarModel {
  final String id;
  final String nombre;
  final String? ciudad;
  final String? direccion;
  final String timezone;
  final String monedaSimbolo;
  final String monedaIso;
  final String? logoUrl;
  final String? whatsapp;
  final String? linkUbicacion;
  final String? facebook;
  final String? instagram;
  final String? tiktok;
  final String slug;
  final bool estado;
  final double comisionPorcentaje;
  final bool moduloDamasActivo;
  final String? tarifaCompaniaId;
  final Map<String, dynamic>? horarios;

  BarModel({
    required this.id,
    required this.nombre,
    this.ciudad,
    this.direccion,
    required this.timezone,
    required this.monedaSimbolo,
    required this.monedaIso,
    this.logoUrl,
    this.whatsapp,
    this.linkUbicacion,
    this.facebook,
    this.instagram,
    this.tiktok,
    required this.slug,
    required this.estado,
    required this.comisionPorcentaje,
    required this.moduloDamasActivo,
    this.tarifaCompaniaId,
    this.horarios,
  });

  factory BarModel.fromJson(Map<String, dynamic> json) {
    final String iso = json['moneda_iso'] ?? 'BOB';
    return BarModel(
      id: json['id'],
      nombre: json['nombre'],
      ciudad: json['ciudad'],
      direccion: json['direccion'],
      timezone: json['timezone'] ?? 'America/La_Paz',
      monedaSimbolo: CurrencyHelper.cleanCurrencySymbol(json['moneda_simbolo'], iso),
      monedaIso: iso,
      logoUrl: json['logo_url'],
      whatsapp: json['whatsapp'],
      linkUbicacion: json['link_ubicacion'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      tiktok: json['tiktok'],
      slug: json['slug'],
      estado: json['estado'] ?? true,
      comisionPorcentaje: (json['comision_porcentaje'] ?? 50.0).toDouble(),
      moduloDamasActivo: json['modulo_damas_activo'] ?? false,
      tarifaCompaniaId: json['tarifa_compania_id'],
      horarios: json['horarios'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'ciudad': ciudad,
      'direccion': direccion,
      'timezone': timezone,
      'moneda_simbolo': monedaSimbolo,
      'moneda_iso': monedaIso,
      'logo_url': logoUrl,
      'whatsapp': whatsapp,
      'link_ubicacion': linkUbicacion,
      'facebook': facebook,
      'instagram': instagram,
      'tiktok': tiktok,
      'comision_porcentaje': comisionPorcentaje,
      'modulo_damas_activo': moduloDamasActivo,
      'tarifa_compania_id': tarifaCompaniaId,
      'horarios': horarios,
    };
  }

  BarModel copyWith({
    String? nombre,
    String? ciudad,
    String? direccion,
    String? timezone,
    String? monedaSimbolo,
    String? monedaIso,
    String? logoUrl,
    String? whatsapp,
    String? linkUbicacion,
    String? facebook,
    String? instagram,
    String? tiktok,
    double? comisionPorcentaje,
    bool? moduloDamasActivo,
    String? tarifaCompaniaId,
    Map<String, dynamic>? horarios,
  }) {
    final String targetIso = monedaIso ?? this.monedaIso;
    return BarModel(
      id: id,
      slug: slug,
      estado: estado,
      nombre: nombre ?? this.nombre,
      ciudad: ciudad ?? this.ciudad,
      direccion: direccion ?? this.direccion,
      timezone: timezone ?? this.timezone,
      monedaSimbolo: CurrencyHelper.cleanCurrencySymbol(
        monedaSimbolo ?? this.monedaSimbolo,
        targetIso,
      ),
      monedaIso: targetIso,
      logoUrl: logoUrl ?? this.logoUrl,
      whatsapp: whatsapp ?? this.whatsapp,
      linkUbicacion: linkUbicacion ?? this.linkUbicacion,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      tiktok: tiktok ?? this.tiktok,
      comisionPorcentaje: comisionPorcentaje ?? this.comisionPorcentaje,
      moduloDamasActivo: moduloDamasActivo ?? this.moduloDamasActivo,
      tarifaCompaniaId: tarifaCompaniaId ?? this.tarifaCompaniaId,
      horarios: horarios ?? this.horarios,
    );
  }
}
