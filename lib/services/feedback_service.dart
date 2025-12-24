import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:vibration/vibration.dart';

/// Unified feedback service for snackbars, toasts, and haptic feedback
class FeedbackService {
  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    VoidCallback? onUndo,
  }) {
    _showHapticFeedback(HapticType.success);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_circle,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.green, width: 1),
        ),
        duration: const Duration(seconds: 3),
        action:
            onUndo != null
                ? SnackBarAction(
                  label: 'UNDO',
                  textColor: Colors.green,
                  onPressed: onUndo,
                )
                : null,
      ),
    );
  }

  /// Show error message
  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    _showHapticFeedback(HapticType.error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.close_circle,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.red, width: 1),
        ),
        duration: const Duration(seconds: 4),
        action:
            onRetry != null
                ? SnackBarAction(
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
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.warning_2,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
                color: const Color(0xFF8B5FBF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.info_circle,
                color: Color(0xFF8B5FBF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF8B5FBF), width: 1),
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5FBF)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
