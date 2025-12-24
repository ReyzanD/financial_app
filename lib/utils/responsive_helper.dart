import 'package:flutter/material.dart';

/// Utility class untuk membantu membuat UI yang responsive
/// Mendukung breakpoints untuk phone, tablet, dan desktop
/// Enhanced dengan landscape support dan adaptive components
class ResponsiveHelper {
  // Breakpoints
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1200.0;
  static const double largeTabletBreakpoint = 900.0;

  /// Cek apakah device adalah tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Cek apakah device adalah phone
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Cek apakah device adalah desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get responsive padding
  /// Default: phone = 16, tablet = 24
  static EdgeInsets padding(
    BuildContext context, {
    double? multiplier,
    double? phone,
    double? tablet,
  }) {
    final basePhone = phone ?? 16.0;
    final baseTablet = tablet ?? 24.0;
    final base = isTablet(context) ? baseTablet : basePhone;
    final value = multiplier != null ? base * multiplier : base;
    return EdgeInsets.all(value);
  }

  /// Get responsive horizontal padding
  static EdgeInsets horizontalPadding(
    BuildContext context, {
    double? multiplier,
    double? phone,
    double? tablet,
  }) {
    final basePhone = phone ?? 16.0;
    final baseTablet = tablet ?? 24.0;
    final base = isTablet(context) ? baseTablet : basePhone;
    final value = multiplier != null ? base * multiplier : base;
    return EdgeInsets.symmetric(horizontal: value);
  }

  /// Get responsive vertical padding
  static EdgeInsets verticalPadding(
    BuildContext context, {
    double? multiplier,
    double? phone,
    double? tablet,
  }) {
    final basePhone = phone ?? 16.0;
    final baseTablet = tablet ?? 24.0;
    final base = isTablet(context) ? baseTablet : basePhone;
    final value = multiplier != null ? base * multiplier : base;
    return EdgeInsets.symmetric(vertical: value);
  }

  /// Get responsive symmetric padding
  static EdgeInsets symmetricPadding(
    BuildContext context, {
    double? horizontal,
    double? vertical,
    double? multiplier,
  }) {
    final h = horizontal ?? 16.0;
    final v = vertical ?? 16.0;
    final mult = multiplier ?? 1.0;
    final hValue = isTablet(context) ? h * 1.5 * mult : h * mult;
    final vValue = isTablet(context) ? v * 1.5 * mult : v * mult;
    return EdgeInsets.symmetric(horizontal: hValue, vertical: vValue);
  }

  /// Get responsive font size
  /// Scales based on device type and text scale factor
  static double fontSize(
    BuildContext context,
    double baseSize, {
    double? phoneMultiplier,
    double? tabletMultiplier,
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final phoneMult = phoneMultiplier ?? 1.0;
    final tabletMult = tabletMultiplier ?? 1.2;
    final deviceMult = isTablet(context) ? tabletMult : phoneMult;
    return baseSize * deviceMult * textScaleFactor;
  }

  /// Get responsive vertical spacing
  static double verticalSpacing(
    BuildContext context,
    double baseSpacing, {
    double? multiplier,
  }) {
    final mult = multiplier ?? 1.0;
    final spacing = isTablet(context) ? baseSpacing * 1.5 * mult : baseSpacing * mult;
    return spacing;
  }

  /// Get responsive horizontal spacing
  static double horizontalSpacing(
    BuildContext context,
    double baseSpacing, {
    double? multiplier,
  }) {
    final mult = multiplier ?? 1.0;
    final spacing = isTablet(context) ? baseSpacing * 1.5 * mult : baseSpacing * mult;
    return spacing;
  }

  /// Get responsive grid cross axis count
  static int gridCrossAxisCount(
    BuildContext context, {
    int phone = 2,
    int tablet = 3,
    int? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    return isTablet(context) ? tablet : phone;
  }

  /// Get max content width for centered layouts
  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200.0;
    }
    if (isTablet(context)) {
      return 800.0;
    }
    return screenWidth(context);
  }

  /// Get responsive icon size
  static double iconSize(
    BuildContext context,
    double baseSize, {
    double? multiplier,
  }) {
    final mult = multiplier ?? 1.0;
    return isTablet(context) ? baseSize * 1.2 * mult : baseSize * mult;
  }

  /// Get responsive border radius
  static double borderRadius(
    BuildContext context,
    double baseRadius, {
    double? multiplier,
  }) {
    final mult = multiplier ?? 1.0;
    return isTablet(context) ? baseRadius * 1.2 * mult : baseRadius * mult;
  }

  /// Get responsive card height
  static double cardHeight(
    BuildContext context,
    double baseHeight, {
    double? multiplier,
  }) {
    final mult = multiplier ?? 1.0;
    return isTablet(context) ? baseHeight * 1.3 * mult : baseHeight * mult;
  }

  /// Get responsive button height
  static double buttonHeight(
    BuildContext context, {
    double? phone,
    double? tablet,
  }) {
    final basePhone = phone ?? 48.0;
    final baseTablet = tablet ?? 56.0;
    return isTablet(context) ? baseTablet : basePhone;
  }

  /// Get responsive modal max width
  static double modalMaxWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 600.0;
    }
    if (isTablet(context)) {
      return 500.0;
    }
    return screenWidth(context);
  }

  /// Get responsive aspect ratio for images/cards
  static double aspectRatio(
    BuildContext context,
    double baseRatio, {
    double? multiplier,
  }) {
    final mult = multiplier ?? 1.0;
    return isTablet(context) ? baseRatio * 1.1 * mult : baseRatio * mult;
  }

  /// Cek apakah device dalam landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Cek apakah device dalam portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get responsive layout berdasarkan orientation
  static T responsiveByOrientation<T>(
    BuildContext context, {
    required T portrait,
    required T landscape,
  }) {
    return isLandscape(context) ? landscape : portrait;
  }

  /// Cek apakah device adalah large tablet
  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeTabletBreakpoint &&
        MediaQuery.of(context).size.width < desktopBreakpoint;
  }

  /// Get responsive grid columns untuk tablet layouts
  static int tabletGridColumns(BuildContext context) {
    if (isLandscape(context)) {
      return 4; // More columns in landscape
    }
    return 3; // Standard tablet columns
  }

  /// Get responsive card width untuk adaptive layouts
  static double adaptiveCardWidth(
    BuildContext context, {
    double? phoneWidth,
    double? tabletWidth,
    double? desktopWidth,
  }) {
    if (isDesktop(context) && desktopWidth != null) {
      return desktopWidth;
    }
    if (isTablet(context)) {
      return tabletWidth ?? screenWidth(context) * 0.45;
    }
    return phoneWidth ?? screenWidth(context) * 0.9;
  }

  /// Get responsive spacing berdasarkan orientation
  static double adaptiveSpacing(
    BuildContext context,
    double baseSpacing, {
    double? landscapeMultiplier,
  }) {
    final mult = landscapeMultiplier ?? 0.8; // Less spacing in landscape
    return isLandscape(context) ? baseSpacing * mult : baseSpacing;
  }

  /// Get breakpoint name untuk debugging
  static String getBreakpointName(BuildContext context) {
    if (isDesktop(context)) return 'desktop';
    if (isLargeTablet(context)) return 'large-tablet';
    if (isTablet(context)) return 'tablet';
    return 'phone';
  }
}

