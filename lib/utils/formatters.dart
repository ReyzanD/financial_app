import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

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

/// Parses a hex color string (e.g. "#3498db", "3498db", "0xFF3498db") into a
/// [Color]. Returns [fallback] instead of throwing when the input is null,
/// empty, or malformed (stored colors can be corrupted / wrong length).
class ColorParsing {
  static Color parse(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null || hex.isEmpty) return fallback;

    var cleaned = hex.trim();
    if (cleaned.startsWith('0x') || cleaned.startsWith('0X')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('#')) {
      cleaned = cleaned.substring(1);
    }

    // Support "AARRGGBB" or "RRGGBB"; normalize to a full 8-digit ARGB hex.
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    } else if (cleaned.length == 8) {
      // already AARRGGBB
    } else {
      return fallback;
    }

    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }
}
