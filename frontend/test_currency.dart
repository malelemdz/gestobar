import 'package:intl/intl.dart';

void main() {
  final formatter0 = NumberFormat.currency(locale: 'es', symbol: '', decimalDigits: 0);
  final formatter2 = NumberFormat.currency(locale: 'es', symbol: '', decimalDigits: 2);
  
  print('CLP (0): ${formatter0.format(15000)}');
  print('USD (2): ${formatter2.format(15000.5)}');
}
