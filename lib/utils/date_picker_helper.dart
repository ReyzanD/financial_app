import 'package:flutter/material.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Helper untuk menampilkan DatePicker dengan tema dark yang konsisten
/// di seluruh aplikasi. Menghilangkan duplikasi boilerplate theming.
class DatePickerHelper {
  /// Menampilkan date picker dengan theme dark kustom.
  static Future<DateTime?> showDarkDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
    String? helpText,
    Locale? locale,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: initialDatePickerMode,
      helpText: helpText,
      locale: locale,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DesignTokens.primaryColor,
              onPrimary: Colors.white,
              surface: DesignTokens.surfaceDark,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: DesignTokens.backgroundDark,
            ),
          ),
          child: child!,
        );
      },
    );
    return picked;
  }
}
