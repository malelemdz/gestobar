import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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

  /// Define el número de dígitos decimales que usa la moneda basada en su código ISO.
  /// Ej: CLP (Chile), COP (Colombia), PYG (Paraguay) no usan decimales (0).
  /// Ej: USD, EUR, BOB usan 2 decimales.
  static int getDecimalDigits(String iso) {
    switch (iso.trim().toUpperCase()) {
      case 'CLP':
      case 'COP':
      case 'PYG':
        return 0;
      default:
        return 2;
    }
  }

  /// Formatea la cantidad (double) según los parámetros de la divisa (miles, decimales).
  /// No incluye el símbolo, solo el número matemático, usando convención 'es' (1.000,50 o 1.000).
  static String formatAmount(double amount, String iso) {
    final decimals = getDecimalDigits(iso);
    final formatter = NumberFormat.currency(
      locale: 'es', // Uso del formato ES para separación de miles (.) y decimales (,) estándar en LATAM
      symbol: '',
      decimalDigits: decimals,
    );
    return formatter.format(amount).trim();
  }

  /// Lee un texto ingresado por el usuario y lo convierte de forma segura a Double
  /// dependiendo de las reglas de decimales de la moneda. Evita que "50.000" (Cincuenta mil)
  /// se lea erróneamente como "Cincuenta punto Cero".
  static double parseAmount(String input, String iso) {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return 0.0;
    
    final decimals = getDecimalDigits(iso);
    
    if (decimals == 0) {
      // Si la moneda no tiene decimales, cualquier punto o coma tecleado es separador de miles.
      // Así que simplemente removemos todo lo que no sea dígito para extraer el número real.
      final onlyDigits = cleanInput.replaceAll(RegExp(r'[^\d]'), '');
      return double.tryParse(onlyDigits) ?? 0.0;
    } else {
      // Si tiene decimales, la gente puede teclear comas o puntos. Estandarizamos a punto.
      final normalized = cleanInput.replaceAll(',', '.');
      return double.tryParse(normalized) ?? 0.0;
    }
  }
}

/// Formateador interactivo para las cajas de texto (TextField).
/// Impide teclear puntos erróneos y formatea el número al vuelo como app bancaria.
class CurrencyInputFormatter extends TextInputFormatter {
  final String iso;

  CurrencyInputFormatter({required this.iso});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final decimals = CurrencyHelper.getDecimalDigits(iso);
    
    // Limpia todo lo que no sea número, coma o punto
    String cleanText = newValue.text.replaceAll(RegExp(r'[^\d\,\.]'), '');
    
    if (decimals == 0) {
      // Sin decimales (Ej: CLP): Bloquea comas y puntos, formatea con separadores de miles
      cleanText = cleanText.replaceAll(RegExp(r'[\,\.]'), '');
      if (cleanText.isEmpty) return newValue.copyWith(text: '');
      
      final value = double.tryParse(cleanText) ?? 0.0;
      final formatted = CurrencyHelper.formatAmount(value, iso); // 1.500.000
      
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      // Con decimales (Ej: USD, BOB): Normaliza todo a coma (estándar ES LATAM)
      cleanText = cleanText.replaceAll('.', ',');
      
      final commaIndex = cleanText.indexOf(',');
      if (commaIndex != -1) {
        // Separa parte entera de parte decimal
        final beforeComma = cleanText.substring(0, commaIndex);
        final afterComma = cleanText.substring(commaIndex + 1).replaceAll(',', ''); // Remueve comas extra
        
        // Limita a máximo los decimales permitidos
        final limitedAfterComma = afterComma.length > decimals ? afterComma.substring(0, decimals) : afterComma;
        
        final cleanBeforeComma = beforeComma.replaceAll(RegExp(r'[^\d]'), '');
        final valueBeforeComma = cleanBeforeComma.isEmpty ? 0 : int.parse(cleanBeforeComma);
        
        final formatter = NumberFormat.decimalPattern('es');
        final formattedBefore = cleanBeforeComma.isEmpty ? '0' : formatter.format(valueBeforeComma);
        
        final finalText = '$formattedBefore,$limitedAfterComma';
        return TextEditingValue(
          text: finalText,
          selection: TextSelection.collapsed(offset: finalText.length),
        );
      } else {
        // Solo parte entera tecleada hasta el momento
        final cleanBeforeComma = cleanText.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanBeforeComma.isEmpty) return newValue.copyWith(text: '');
        
        final value = int.parse(cleanBeforeComma);
        final formatter = NumberFormat.decimalPattern('es');
        final formatted = formatter.format(value);
        
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }
}
