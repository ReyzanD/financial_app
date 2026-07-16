import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Unified feedback service for snackbars, toasts, and haptic feedback
class FeedbackService {
  /// Show success message
  static void showSuccess(BuildContext context, String message, {VoidCallback? onUndo}) {
    _showHapticFeedback(HapticType.success);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Iconsax.tick_circle, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: const BorderSide(color: Colors.green, width: 1),
        ),
        duration: const Duration(seconds: 3),
        action:
            onUndo != null
                ? SnackBarAction(
                  // TODO: Localize — no BuildContext available in service
                  label: 'UNDO',
                  textColor: Colors.green,
                  onPressed: onUndo,
                )
                : null,
      ),
    );
  }

  /// Show error message
  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
    _showHapticFeedback(HapticType.error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Iconsax.close_circle, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: const BorderSide(color: Colors.red, width: 1),
        ),
        duration: const Duration(seconds: 4),
        action:
            onRetry != null
                ? SnackBarAction(
                  // TODO: Localize — no BuildContext available in service
                  label: 'COBA LAGI',
                  textColor: Colors.red,
                  onPressed: onRetry,
                )
                : null,
      ),
    );
  }

  /// Show warning message
  static void showWarning(BuildContext context, String message) {
    _showHapticFeedback(HapticType.warning);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Iconsax.warning_2, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: const BorderSide(color: Colors.orange, width: 1),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info message
  static void showInfo(BuildContext context, String message) {
    _showHapticFeedback(HapticType.light);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.info_circle, color: DesignTokens.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: const BorderSide(color: DesignTokens.primaryColor, width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show loading indicator
  static void showLoading(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
        duration: const Duration(days: 365), // Long duration for loading
      ),
    );
  }

  /// Hide snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Haptic feedback
  static Future<void> _showHapticFeedback(HapticType type) async {
    if (await Vibration.hasVibrator()) {
      switch (type) {
        case HapticType.light:
          Vibration.vibrate(duration: 10);
          break;
        case HapticType.medium:
          Vibration.vibrate(duration: 20);
          break;
        case HapticType.heavy:
          Vibration.vibrate(duration: 30);
          break;
        case HapticType.success:
          Vibration.vibrate(duration: 15);
          break;
        case HapticType.warning:
          Vibration.vibrate(duration: 20, pattern: [0, 20, 50, 20]);
          break;
        case HapticType.error:
          Vibration.vibrate(duration: 30, pattern: [0, 30, 100, 30]);
          break;
      }
    }
  }

  /// Standalone haptic feedback (for buttons, etc.)
  static Future<void> haptic(HapticType type) async {
    await _showHapticFeedback(type);
  }
}

/// Haptic feedback types
enum HapticType { light, medium, heavy, success, warning, error }
