class CurrencyHelper {
  /// Devuelve el símbolo de la moneda a partir de su código ISO.
  /// Si no se reconoce o no tiene símbolo especial, se retorna '$' por defecto.
  static String getSymbolFromIso(String iso) {
    switch (iso.trim().toUpperCase()) {
      case 'BOB':
      case 'VES':
        return 'Bs';
      case 'PEN':
        return 'S/';
      case 'EUR':
        return '€';
      case 'BRL':
        return 'R\$';
      case 'CRC':
      case 'SVC':
        return '₡';
      case 'GTQ':
        return 'Q';
      case 'HNL':
        return 'L';
      case 'NIO':
        return 'C\$';
      case 'PAB':
        return 'B/.';
      case 'PYG':
        return '₲';
      default:
        return '\$'; // Dólar y cualquier otro peso/moneda por defecto ($)
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
        return 'Dólar estadounidense (\$)';
      case 'BOB':
        return 'Boliviano (Bs)';
      case 'BRL':
        return 'Real Brasileño (R\$)';
      case 'CLP':
        return 'Peso Chileno (\$)';
      case 'COP':
        return 'Peso Colombiano (\$)';
      case 'CRC':
        return 'Colón Costarricense (₡)';
      case 'CUP':
        return 'Peso Cubano (\$)';
      case 'DOP':
        return 'Peso Dominicano (\$)';
      case 'EUR':
        return 'Euro (€)';
      case 'GTQ':
        return 'Quetzal Guatemalteco (Q)';
      case 'HNL':
        return 'Lempira Hondureño (L)';
      case 'MXN':
        return 'Peso Mexicano (\$)';
      case 'NIO':
        return 'Córdoba Nicaragüense (C\$)';
      case 'PAB':
        return 'Balboa Panameño (B/.)';
      case 'PEN':
        return 'Sol Peruano (S/)';
      case 'PYG':
        return 'Guaraní Paraguayo (₲)';
      case 'SVC':
        return 'Colón Salvadoreño (₡)';
      case 'UYU':
        return 'Peso Uruguayo (\$)';
      case 'VES':
        return 'Bolívar Venezolano (Bs)';
      default:
        return '$iso (\$)';
    }
  }
}
