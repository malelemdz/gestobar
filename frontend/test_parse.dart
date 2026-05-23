import 'package:intl/intl.dart';

void main() {
  String inputUser = "50.000";
  
  double? normal = double.tryParse(inputUser);
  
  final formatter = NumberFormat.currency(locale: 'es', symbol: '', decimalDigits: 0);
  num? intlParse;
  try {
    intlParse = formatter.parse(inputUser);
  } catch (e) {
    intlParse = null;
  }
  
  print('Texto ingresado: ' + inputUser);
  print('Lectura por defecto (tryParse): ' + normal.toString());
  print('Lectura con NumberFormat: ' + intlParse.toString());
}
