import 'package:intl/intl.dart';

// Definición del formateador
final currencyFormatter = NumberFormat.currency(
  locale: 'es_CO',          // O el locale de tu preferencia ('es_ES', 'en_US', etc.)
  symbol: '\$',
  decimalDigits: 2,         // Mantiene los dos decimales que ya usabas
);

// Función para formatear (opcional, pero más limpio)
String formatCurrency(double amount) {
  return currencyFormatter.format(amount);
}