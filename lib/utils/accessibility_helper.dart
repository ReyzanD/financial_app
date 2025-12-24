import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:financial_app/utils/responsive_helper.dart';

/// Helper class untuk accessibility features
/// Memastikan aplikasi accessible untuk semua users
class AccessibilityHelper {
  // Minimum touch target size (48x48dp sesuai Material Design)
  static const double minTouchTarget = 48.0;

  // Get minimum touch target size dengan responsive scaling
  static double getTouchTargetSize(BuildContext context) {
    return ResponsiveHelper.iconSize(context, minTouchTarget);
  }

  // Ensure widget meets minimum touch target
  static Widget ensureTouchTarget({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final size = getTouchTargetSize(context);
    final widget = SizedBox(
      width: size,
      height: size,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: widget,
      );
    }
    return widget;
  }

  // Create semantic label untuk screen readers
  static String createSemanticLabel({
    required String label,
    String? hint,
    String? value,
    bool isButton = false,
    bool isHeader = false,
  }) {
    final buffer = StringBuffer();
    
    if (isHeader) {
      buffer.write('Heading: ');
    } else if (isButton) {
      buffer.write('Button: ');
    }
    
    buffer.write(label);
    
    if (value != null) {
      buffer.write(', Value: $value');
    }
    
    if (hint != null) {
      buffer.write(', Hint: $hint');
    }
    
    return buffer.toString();
  }

  // Check color contrast ratio (WCAG AA compliance)
  static double getContrastRatio(Color foreground, Color background) {
    final fgLuminance = _getLuminance(foreground);
    final bgLuminance = _getLuminance(background);
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  // Check if color combination meets WCAG AA (4.5:1 for normal text, 3:1 for large text)
  static bool meetsWCAGAA(Color foreground, Color background, {bool isLargeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    return isLargeText ? ratio >= 3.0 : ratio >= 4.5;
  }

  // Get accessible text color based on background
  static Color getAccessibleTextColor(Color backgroundColor, {bool isLargeText = false}) {
    final white = Colors.white;
    final black = Colors.black;
    
    final whiteRatio = getContrastRatio(white, backgroundColor);
    final blackRatio = getContrastRatio(black, backgroundColor);
    
    final minRatio = isLargeText ? 3.0 : 4.5;
    
    if (whiteRatio >= minRatio) return white;
    if (blackRatio >= minRatio) return black;
    
    // Fallback: return color with better contrast
    return whiteRatio > blackRatio ? white : black;
  }

  // Calculate relative luminance (for contrast calculation)
  static double _getLuminance(Color color) {
    final r = _linearize(color.red / 255.0);
    final g = _linearize(color.green / 255.0);
    final b = _linearize(color.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearize(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  // Create accessible button dengan proper semantics
  static Widget createAccessibleButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    String? hint,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    double? minWidth,
    double? minHeight,
  }) {
    final size = getTouchTargetSize(context);
    final effectiveMinWidth = minWidth ?? size;
    final effectiveMinHeight = minHeight ?? size;
    
    // Ensure accessible colors
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;
    final fgColor = foregroundColor ?? 
        getAccessibleTextColor(bgColor, isLargeText: true);

    return Semantics(
      label: createSemanticLabel(
        label: label,
        hint: hint,
        isButton: true,
      ),
      hint: hint,
      button: true,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          minimumSize: Size(effectiveMinWidth, effectiveMinHeight),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.horizontalSpacing(context, 16),
            vertical: ResponsiveHelper.verticalSpacing(context, 12),
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: ResponsiveHelper.iconSize(context, 20)),
                  SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }

  // Create accessible icon button
  static Widget createAccessibleIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required String label,
    String? hint,
    Color? color,
    double? iconSize,
  }) {
    final size = getTouchTargetSize(context);
    final effectiveIconSize = iconSize ?? ResponsiveHelper.iconSize(context, 24);

    return Semantics(
      label: createSemanticLabel(
        label: label,
        hint: hint,
        isButton: true,
      ),
      hint: hint,
      button: true,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: effectiveIconSize, color: color),
        iconSize: size,
        tooltip: hint ?? label,
      ),
    );
  }

  // Create accessible text dengan proper semantics
  static Widget createAccessibleText({
    required BuildContext context,
    required String text,
    String? semanticLabel,
    bool isHeader = false,
    TextStyle? style,
  }) {
    return Semantics(
      label: semanticLabel ?? text,
      header: isHeader,
      child: Text(
        text,
        style: style,
      ),
    );
  }

  // Announce changes untuk screen readers
  static void announce(BuildContext context, String message, {bool polite = true}) {
    // Use SemanticsService for screen reader announcements
    // Note: SemanticsService is available in Flutter framework
    SemanticsService.announce(
      message,
      TextDirection.ltr,
    );
  }

  // Get text scale factor dari MediaQuery
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  // Check if user has large text enabled
  static bool hasLargeText(BuildContext context) {
    return getTextScaleFactor(context) > 1.0;
  }

  // Adjust font size berdasarkan text scale factor
  static double getAccessibleFontSize(
    BuildContext context,
    double baseSize, {
    double? maxScaleFactor,
  }) {
    final scaleFactor = getTextScaleFactor(context);
    final maxScale = maxScaleFactor ?? 1.5;
    final effectiveScale = scaleFactor > maxScale ? maxScale : scaleFactor;
    return baseSize * effectiveScale;
  }
}

