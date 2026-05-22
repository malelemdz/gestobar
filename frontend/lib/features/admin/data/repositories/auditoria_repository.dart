import 'package:dio/dio.dart';
import '../models/auditoria_model.dart';

class AuditoriaRepository {
  final Dio _dio;

  AuditoriaRepository(this._dio);

  Future<List<AuditoriaModel>> getAuditoria({
    String? usuarioId,
    String? modulo,
    String? accion,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final queryParams = <String, dynamic>{};
    if (usuarioId != null && usuarioId.isNotEmpty) queryParams['usuario_id'] = usuarioId;
    if (modulo != null && modulo.isNotEmpty) queryParams['modulo'] = modulo;
    if (accion != null && accion.isNotEmpty) queryParams['accion'] = accion;
    if (fechaInicio != null && fechaInicio.isNotEmpty) queryParams['fecha_inicio'] = fechaInicio;
    if (fechaFin != null && fechaFin.isNotEmpty) queryParams['fecha_fin'] = fechaFin;

    try {
      final response = await _dio.get('/auditoria', queryParameters: queryParams);
      final List data = response.data;
      return data.map((json) => AuditoriaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar la bitácora: $e');
    }
  }
}
