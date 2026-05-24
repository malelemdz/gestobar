import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  String jsonResponse = '{"precio_unitario": "27500.00"}';
  var data = jsonDecode(jsonResponse);
  
  // Simulando el parseo de tu clase VariantePrecio
  double parsedDouble = (data['precio_unitario'] is num)
      ? (data['precio_unitario'] as num).toDouble()
      : double.tryParse(data['precio_unitario']?.toString() ?? '') ?? 0.0;
      
  print('El double parseado es: $parsedDouble');
  
  var formatterCOP = NumberFormat.currency(
    symbol: '',
    decimalDigits: 0,
    locale: 'es',
  );
  
  print('Como se ve en pantalla (COP): ${formatterCOP.format(parsedDouble)}');
}
