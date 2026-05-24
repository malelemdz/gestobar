import 'package:intl/intl.dart';

void main() {
  double precioBD = 27420.00;
  
  var formatterES = NumberFormat.currency(
    symbol: '',
    decimalDigits: 0,
    locale: 'es',
  );
  
  print('Formato ES para 27420.00: ${formatterES.format(precioBD)}');
}
