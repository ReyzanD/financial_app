import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/accessibility_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Enhanced error state widget dengan retry mechanism dan accessibility
class EnhancedErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final IconData? icon;
  final bool isCompact;
  final bool showDetails;

  const EnhancedErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon,
    this.isCompact = false,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorIcon = icon ?? Iconsax.warning_2;

    return Semantics(
      label: AccessibilityHelper.createSemanticLabel(
        label: title,
        hint: message,
      ),
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.padding(
          context,
          multiplier: isCompact ? 1.5 : 2.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              padding: ResponsiveHelper.padding(context, multiplier: 1.5),
              decoration: BoxDecoration(
                color: DesignTokens.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorIcon,
                size: ResponsiveHelper.iconSize(
                  context,
                  isCompact ? 48 : 64,
                ),
                color: DesignTokens.errorColor,
              ),
            ),
            SizedBox(
              height: ResponsiveHelper.verticalSpacing(context, 24),
            ),

            // Title
            AccessibilityHelper.createAccessibleText(
              context: context,
              text: title,
              semanticLabel: title,
              isHeader: true,
              style: GoogleFonts.poppins(
                color: DesignTokens.getTextColor(context),
                fontSize: ResponsiveHelper.fontSize(
                  context,
                  DesignTokens.fontSizeHeadlineSmall,
                ),
                fontWeight: DesignTokens.weightBold,
              ),
            ),
            SizedBox(
              height: ResponsiveHelper.verticalSpacing(context, 12),
            ),

            // Message
            AccessibilityHelper.createAccessibleText(
              context: context,
              text: message,
              semanticLabel: message,
              style: GoogleFonts.poppins(
                color: DesignTokens.getTextColor(context, isPrimary: false),
                fontSize: ResponsiveHelper.fontSize(
                  context,
                  DesignTokens.fontSizeBodyMedium,
                ),
                height: 1.5,
              ),
            ),

            // Retry Button
            if (onRetry != null) ...[
              SizedBox(
                height: ResponsiveHelper.verticalSpacing(context, 24),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AccessibilityHelper.createAccessibleButton(
                    context: context,
                    label: retryLabel ?? 'Coba Lagi',
                    onPressed: onRetry!,
                    backgroundColor: DesignTokens.primaryColor,
                    icon: Iconsax.refresh,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Predefined error states
  factory EnhancedErrorState.networkError({VoidCallback? onRetry}) {
    return EnhancedErrorState(
      title: 'Tidak Ada Koneksi',
      message: 'Periksa koneksi internet Anda dan coba lagi',
      onRetry: onRetry,
      icon: Iconsax.wifi_square,
    );
  }

  factory EnhancedErrorState.serverError({VoidCallback? onRetry}) {
    return EnhancedErrorState(
      title: 'Server Error',
      message: 'Server sedang mengalami masalah. Silakan coba lagi nanti',
      onRetry: onRetry,
      icon: Iconsax.cloud_remove,
    );
  }

  factory EnhancedErrorState.timeoutError({VoidCallback? onRetry}) {
    return EnhancedErrorState(
      title: 'Request Timeout',
      message: 'Koneksi terlalu lama. Periksa koneksi internet Anda',
      onRetry: onRetry,
      icon: Iconsax.timer,
    );
  }

  factory EnhancedErrorState.unauthorized({VoidCallback? onRetry}) {
    return EnhancedErrorState(
      title: 'Sesi Berakhir',
      message: 'Sesi Anda telah berakhir. Silakan login kembali',
      onRetry: onRetry,
      retryLabel: 'Login',
      icon: Iconsax.lock,
    );
  }

  factory EnhancedErrorState.generic({
    required String message,
    VoidCallback? onRetry,
  }) {
    return EnhancedErrorState(
      title: 'Terjadi Kesalahan',
      message: message,
      onRetry: onRetry,
    );
  }
}

