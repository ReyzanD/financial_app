import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatRupiah(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits:
          0, // Indonesian Rupiah typically doesn't show decimal places
    );

    // Format with proper Indonesian thousand separators
    String formatted = formatter.format(amount);

    // Ensure we have proper spacing after the Rp symbol
    if (!formatted.startsWith('Rp ')) {
      formatted = formatted.replaceFirst('Rp', 'Rp ');
    }

    return formatted;
  }
}
