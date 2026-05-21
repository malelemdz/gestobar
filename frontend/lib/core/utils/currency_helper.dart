class CurrencyHelper {
  /// Devuelve el símbolo de la moneda a partir de su código ISO.
  /// Si no se reconoce o no tiene símbolo especial, se retorna '$' por defecto.
  static String getSymbolFromIso(String iso) {
    switch (iso.trim().toUpperCase()) {
      case 'BOB':
        return 'Bs';
      case 'PEN':
        return 'S/';
      case 'EUR':
        return '€';
      default:
        return '\$'; // Dólar y cualquier otro por defecto ($)
    }
  }

  /// Limpia y garantiza que el símbolo de moneda no sea una firma ISO (como BOB, MXN, CLP).
  /// Si el símbolo coincide con un ISO de 3 letras, o está vacío, se resuelve desde el ISO.
  static String cleanCurrencySymbol(String? simbolo, String? iso) {
    final String cleanSimbolo = (simbolo ?? '').trim();
    final String cleanIso = (iso ?? '').trim().toUpperCase();

    // Patrón para detectar códigos ISO (3 letras mayúsculas)
    final isoPattern = RegExp(r'^[A-Z]{3}$');

    if (cleanSimbolo.isEmpty || isoPattern.hasMatch(cleanSimbolo.toUpperCase())) {
      return getSymbolFromIso(cleanIso.isNotEmpty ? cleanIso : cleanSimbolo);
    }

    return cleanSimbolo;
  }

  /// Devuelve una etiqueta amigable para la selección de monedas sin exponer códigos ISO puros.
  static String getCurrencyLabel(String iso) {
    switch (iso.trim().toUpperCase()) {
      case 'USD':
        return 'Dólar (\$)';
      case 'BOB':
        return 'Boliviano (Bs)';
      case 'CLP':
        return 'Peso Chileno (\$)';
      case 'COP':
        return 'Peso Colombiano (\$)';
      case 'PEN':
        return 'Sol Peruano (S/)';
      case 'MXN':
        return 'Peso Mexicano (\$)';
      case 'ARS':
        return 'Peso Argentino (\$)';
      case 'EUR':
        return 'Euro (€)';
      default:
        return '$iso (\$)';
    }
  }
}
