import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/l10n/app_localizations.dart';

/// Beautiful empty state widget with icon, message, and optional action
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient background
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    (iconColor ?? const Color(0xFF8B5FBF)).withOpacity(0.2),
                    (iconColor ?? const Color(0xFF8B5FBF)).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                icon,
                size: 64,
                color: iconColor ?? const Color(0xFF8B5FBF),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),

            // Action button (if provided)
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(Iconsax.add, color: Colors.white),
                label: Text(
                  actionText!,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor ?? const Color(0xFF8B5FBF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pre-configured empty states for common scenarios
class EmptyStates {
  /// No transactions
  static Widget noTransactions(VoidCallback onAdd, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.wallet,
      title: l10n?.no_transactions_title ?? 'Belum Ada Transaksi',
      subtitle: l10n?.no_transactions_subtitle ?? 'Mulai catat pengeluaran dan pemasukan Anda',
      actionText: l10n?.add_transaction ?? 'Tambah Transaksi',
      onAction: onAdd,
    );
  }

  /// No budgets
  static Widget noBudgets(VoidCallback onAdd, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.chart,
      title: l10n?.no_budgets_title ?? 'Belum Ada Budget',
      subtitle: l10n?.no_budgets_subtitle ?? 'Atur budget untuk mengontrol pengeluaran Anda',
      actionText: l10n?.create_budget ?? 'Buat Budget',
      onAction: onAdd,
    );
  }

  /// No goals
  static Widget noGoals(VoidCallback onAdd, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.flag,
      title: l10n?.no_goals_title ?? 'Belum Ada Target',
      subtitle: l10n?.no_goals_subtitle ?? 'Tetapkan target keuangan dan capai impian Anda',
      actionText: l10n?.add_target ?? 'Tambah Target',
      onAction: onAdd,
    );
  }

  /// No notifications
  static Widget noNotifications(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.notification,
      title: l10n?.no_notifications_title ?? 'Belum Ada Notifikasi',
      subtitle: l10n?.no_notifications_subtitle ?? 'Notifikasi Anda akan muncul di sini',
    );
  }

  /// No search results
  static Widget noSearchResults(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.search_normal,
      title: l10n?.no_search_results_title ?? 'Tidak Ada Hasil',
      subtitle: l10n?.no_search_results_subtitle ?? 'Coba kata kunci lain atau filter berbeda',
    );
  }

  /// No obligations
  static Widget noObligations(VoidCallback onAdd, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.receipt_text,
      title: l10n?.no_obligations_title ?? 'Belum Ada Kewajiban',
      subtitle: l10n?.no_obligations_subtitle ?? 'Catat tagihan dan subscription Anda',
      actionText: l10n?.add_obligation ?? 'Tambah Kewajiban',
      onAction: onAdd,
    );
  }

  /// No recurring transactions
  static Widget noRecurringTransactions(VoidCallback onAdd, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.repeat,
      title: l10n?.no_recurring_transactions_title ?? 'Belum Ada Transaksi Berulang',
      subtitle: l10n?.no_recurring_transactions_subtitle ?? 'Otomatis catat transaksi yang terjadi secara rutin',
      actionText: l10n?.add_recurring_transaction ?? 'Tambah Transaksi Berulang',
      onAction: onAdd,
    );
  }

  /// Network error
  static Widget networkError(VoidCallback onRetry, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.wifi,
      title: l10n?.no_connection_title ?? 'Tidak Ada Koneksi',
      subtitle: l10n?.no_connection_subtitle ?? 'Periksa koneksi internet Anda dan coba lagi',
      actionText: l10n?.try_again ?? 'Coba Lagi',
      onAction: onRetry,
      iconColor: Colors.orange,
    );
  }

  /// Server error
  static Widget serverError(VoidCallback onRetry, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyState(
      icon: Iconsax.warning_2,
      title: l10n?.server_error_title ?? 'Terjadi Kesalahan',
      subtitle: l10n?.server_error_subtitle ?? 'Server sedang bermasalah. Coba lagi dalam beberapa saat',
      actionText: l10n?.try_again ?? 'Coba Lagi',
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}
