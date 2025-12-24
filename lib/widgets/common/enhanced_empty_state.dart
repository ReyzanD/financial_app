import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/accessibility_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Enhanced empty state widget dengan illustrations, CTAs, dan accessibility
class EnhancedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final bool isCompact;

  const EnhancedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? DesignTokens.textSecondaryDark;

    return Semantics(
      label: AccessibilityHelper.createSemanticLabel(
        label: title,
        hint: description,
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
            // Icon dengan animation
            Container(
              padding: ResponsiveHelper.padding(context, multiplier: 2.0),
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: ResponsiveHelper.iconSize(
                  context,
                  isCompact ? 48 : 64,
                ),
                color: effectiveIconColor,
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

            // Description
            AccessibilityHelper.createAccessibleText(
              context: context,
              text: description,
              semanticLabel: description,
              style: GoogleFonts.poppins(
                color: DesignTokens.getTextColor(context, isPrimary: false),
                fontSize: ResponsiveHelper.fontSize(
                  context,
                  DesignTokens.fontSizeBodyMedium,
                ),
                height: 1.5,
              ),
            ),

            // Action Button
            if (actionLabel != null && onAction != null) ...[
              SizedBox(
                height: ResponsiveHelper.verticalSpacing(context, 24),
              ),
              AccessibilityHelper.createAccessibleButton(
                context: context,
                label: actionLabel!,
                onPressed: onAction!,
                backgroundColor: DesignTokens.primaryColor,
                minWidth: ResponsiveHelper.screenWidth(context) * 0.6,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Predefined empty states
  factory EnhancedEmptyState.noTransactions({VoidCallback? onAdd}) {
    return EnhancedEmptyState(
      icon: Iconsax.receipt_2,
      title: 'Belum Ada Transaksi',
      description: 'Mulai catat transaksi pertama Anda untuk melihat ringkasan keuangan',
      actionLabel: 'Tambah Transaksi',
      onAction: onAdd,
    );
  }

  factory EnhancedEmptyState.noBudgets({VoidCallback? onAdd}) {
    return EnhancedEmptyState(
      icon: Iconsax.wallet_3,
      title: 'Belum Ada Budget',
      description: 'Buat budget untuk mengontrol pengeluaran dan mencapai tujuan keuangan',
      actionLabel: 'Buat Budget',
      onAction: onAdd,
    );
  }

  factory EnhancedEmptyState.noGoals({VoidCallback? onAdd}) {
    return EnhancedEmptyState(
      icon: Iconsax.flag,
      title: 'Belum Ada Tujuan',
      description: 'Tetapkan tujuan keuangan untuk memotivasi menabung dan merencanakan masa depan',
      actionLabel: 'Buat Tujuan',
      onAction: onAdd,
    );
  }

  factory EnhancedEmptyState.noData({
    required String title,
    required String description,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return EnhancedEmptyState(
      icon: Iconsax.document,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  factory EnhancedEmptyState.searchEmpty({String? query}) {
    return EnhancedEmptyState(
      icon: Iconsax.search_normal,
      title: 'Tidak Ada Hasil',
      description: query != null
          ? 'Tidak ada hasil untuk "$query". Coba kata kunci lain.'
          : 'Mulai ketik untuk mencari transaksi, budget, atau tujuan',
      isCompact: true,
    );
  }
}

