import 'package:flutter/material.dart';

/// Design tokens untuk konsistensi visual di seluruh aplikasi
/// Mengikuti Material Design 3 principles dengan customizations
class DesignTokens {
  // Colors
  static const Color primaryColor = Color(0xFF8B5FBF);
  static const Color secondaryColor = Color(0xFF6A3093);
  static const Color accentColor = Color(0xFF8B5FBF);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);

  // Surface Colors
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceLight = Colors.white;
  static const Color backgroundDark = Colors.black;
  static const Color backgroundLight = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textTertiaryDark = Color(0xFF808080);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF424242);
  static const Color textTertiaryLight = Color(0xFF757575);

  // Border Colors
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFFE0E0E0);

  // Elevation System (Material Design 3)
  static const List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevation3 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> elevation4 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> elevation5 = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  // Custom Elevation untuk Cards
  static List<BoxShadow> cardElevation({
    Color? color,
    double blurRadius = 15,
    double spreadRadius = 2,
  }) {
    return [
      BoxShadow(
        color: (color ?? primaryColor).withOpacity(0.3),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // Typography Scale
  static const double fontSizeDisplayLarge = 57.0;
  static const double fontSizeDisplayMedium = 45.0;
  static const double fontSizeDisplaySmall = 36.0;
  static const double fontSizeHeadlineLarge = 32.0;
  static const double fontSizeHeadlineMedium = 28.0;
  static const double fontSizeHeadlineSmall = 24.0;
  static const double fontSizeTitleLarge = 22.0;
  static const double fontSizeTitleMedium = 16.0;
  static const double fontSizeTitleSmall = 14.0;
  static const double fontSizeBodyLarge = 16.0;
  static const double fontSizeBodyMedium = 14.0;
  static const double fontSizeBodySmall = 12.0;
  static const double fontSizeLabelLarge = 14.0;
  static const double fontSizeLabelMedium = 12.0;
  static const double fontSizeLabelSmall = 11.0;

  // Font Weights
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  // Spacing System (8px base unit)
  static const double spacing0 = 0.0;
  static const double spacing1 = 4.0;
  static const double spacing2 = 8.0;
  static const double spacing3 = 12.0;
  static const double spacing4 = 16.0;
  static const double spacing5 = 20.0;
  static const double spacing6 = 24.0;
  static const double spacing7 = 32.0;
  static const double spacing8 = 40.0;
  static const double spacing9 = 48.0;
  static const double spacing10 = 56.0;
  static const double spacing11 = 64.0;
  static const double spacing12 = 72.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusRound = 999.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;
  static const double iconSizeXXLarge = 48.0;

  // Touch Target Sizes (Accessibility)
  static const double touchTargetMin = 48.0;

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVerySlow = Duration(milliseconds: 800);

  // Animation Curves
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveAccelerate = Curves.easeIn;
  static const Curve curveEmphasized = Curves.easeInOutCubic;

  // Transaction Type Colors
  static Color getTransactionTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return successColor;
      case 'expense':
        return errorColor;
      case 'transfer':
        return infoColor;
      default:
        return primaryColor;
    }
  }

  // Category Colors (can be extended)
  static Color getCategoryColor(String category) {
    // Default color scheme, can be customized per category
    final colors = [
      primaryColor,
      secondaryColor,
      successColor,
      warningColor,
      errorColor,
      infoColor,
    ];
    final index = category.hashCode % colors.length;
    return colors[index.abs()];
  }

  // Get elevation berdasarkan importance level
  static List<BoxShadow> getElevation(int level) {
    switch (level) {
      case 1:
        return elevation1;
      case 2:
        return elevation2;
      case 3:
        return elevation3;
      case 4:
        return elevation4;
      case 5:
        return elevation5;
      default:
        return elevation2;
    }
  }

  // Get text color berdasarkan theme
  static Color getTextColor(BuildContext context, {bool isPrimary = true}) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return isPrimary ? textPrimaryDark : textSecondaryDark;
    } else {
      return isPrimary ? textPrimaryLight : textSecondaryLight;
    }
  }

  // Get surface color berdasarkan theme
  static Color getSurfaceColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? surfaceDark : surfaceLight;
  }

  // Get border color berdasarkan theme
  static Color getBorderColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? borderDark : borderLight;
  }
}

