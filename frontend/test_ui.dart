import 'package:intl/intl.dart';

void main() {
  double precioBD = 35000.00;
  
  // Como lo formatea la app para COP
  var formatCOP = NumberFormat.currency(
    symbol: '',
    decimalDigits: 0,
    locale: 'es',
  );
  
  print('Si el backend manda 35000, Dart lo pinta como: ${formatCOP.format(precioBD)}');
  print('Longitud del string: ${formatCOP.format(precioBD).length}');
}
