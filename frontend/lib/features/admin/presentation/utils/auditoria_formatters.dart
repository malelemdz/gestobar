import '../../../../core/utils/currency_helper.dart';

class AuditoriaFormatters {
  static String formatMessageWithCurrency(String? message, String currencyIso, String currencySymbol) {
    if (message == null) return 'Acción registrada';
    final regExp = RegExp(r'\$([0-9]+(?:\.[0-9]+)?)');
    
    return message.replaceAllMapped(regExp, (match) {
      final valStr = match.group(1);
      if (valStr == null) return match.group(0)!;
      final val = double.tryParse(valStr);
      if (val == null) return match.group(0)!;
      return '$currencySymbol${CurrencyHelper.formatAmount(val, currencyIso)}';
    });
  }

  static String formatAction(String action) {
    if (action.isEmpty) return '';
    final knownTranslations = {
      'APERTURA': 'Apertura de caja',
      'CIERRE': 'Cierre de caja',
      'REGISTRAR_MOVIMIENTO': 'Registrar movimiento',
      'REGISTRAR_VENTA': 'Registrar venta',
      'Inicio de Sesión': 'Inicio de sesión',
      'Inicio de Sesión Fallido': 'Inicio de sesión fallido',
      'Crear': 'Crear',
      'Editar': 'Editar',
      'Eliminar': 'Eliminar',
    };

    if (knownTranslations.containsKey(action)) {
      return knownTranslations[action]!;
    }

    String formatted = action.replaceAll('_', ' ').trim();
    if (formatted.isEmpty) return '';
    formatted = formatted.toLowerCase();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  static String formatModulo(String modulo) {
    if (modulo.isEmpty) return '';
    String formatted = modulo.replaceAll('_', ' ').trim();
    if (formatted.isEmpty) return '';
    formatted = formatted.toLowerCase();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  static String formatIpAddress(String? ip) {
    if (ip == null) return 'Desconocido';
    if (ip.startsWith('::ffff:')) {
      return ip.substring(7);
    }
    if (ip == '::1') {
      return '127.0.0.1 (Localhost)';
    }
    return ip;
  }

  static String formatFieldKey(String key) {
    if (key.isEmpty) return '';
    final translations = {
      'nombre': 'Nombre',
      'username': 'Nombre de usuario',
      'estado': 'Estado',
      'celular': 'Celular',
      'identificacion': 'Identificación',
      'nacionalidad': 'Nacionalidad',
      'direccion': 'Dirección',
      'genero': 'Género',
      'foto_url': 'Foto',
      'rol_id': 'Rol',
      'rol_nombre': 'Nombre de rol',
      'precio': 'Precio',
      'descripcion': 'Descripción',
      'disponible': 'Disponible',
      'orden': 'Orden',
      'bar_id': 'Bar',
      'bar_slug': 'Slug del bar',
      'monto_apertura': 'Monto de apertura',
      'monto_cierre': 'Monto de cierre',
      'monto_real': 'Monto real',
      'diferencia': 'Diferencia',
      'comision': 'Comisión',
      'tarifa_id': 'Tarifa',
    };
    if (translations.containsKey(key)) {
      return translations[key]!;
    }
    String formatted = key.replaceAll('_', ' ').trim();
    if (formatted.isEmpty) return '';
    formatted = formatted.toLowerCase();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}
