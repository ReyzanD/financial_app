import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
  static Widget noTransactions(VoidCallback onAdd) {
    return EmptyState(
      icon: Iconsax.wallet,
      title: 'Belum Ada Transaksi',
      subtitle: 'Mulai catat pengeluaran dan pemasukan Anda',
      actionText: 'Tambah Transaksi',
      onAction: onAdd,
    );
  }

  /// No budgets
  static Widget noBudgets(VoidCallback onAdd) {
    return EmptyState(
      icon: Iconsax.chart,
      title: 'Belum Ada Budget',
      subtitle: 'Atur budget untuk mengontrol pengeluaran Anda',
      actionText: 'Buat Budget',
      onAction: onAdd,
    );
  }

  /// No goals
  static Widget noGoals(VoidCallback onAdd) {
    return EmptyState(
      icon: Iconsax.flag,
      title: 'Belum Ada Target',
      subtitle: 'Tetapkan target keuangan dan capai impian Anda',
      actionText: 'Tambah Target',
      onAction: onAdd,
    );
  }

  /// No notifications
  static Widget noNotifications() {
    return EmptyState(
      icon: Iconsax.notification,
      title: 'Belum Ada Notifikasi',
      subtitle: 'Notifikasi Anda akan muncul di sini',
    );
  }

  /// No search results
  static Widget noSearchResults() {
    return EmptyState(
      icon: Iconsax.search_normal,
      title: 'Tidak Ada Hasil',
      subtitle: 'Coba kata kunci lain atau filter berbeda',
    );
  }

  /// No obligations
  static Widget noObligations(VoidCallback onAdd) {
    return EmptyState(
      icon: Iconsax.receipt_text,
      title: 'Belum Ada Kewajiban',
      subtitle: 'Catat tagihan dan subscription Anda',
      actionText: 'Tambah Kewajiban',
      onAction: onAdd,
    );
  }

  /// No recurring transactions
  static Widget noRecurringTransactions(VoidCallback onAdd) {
    return EmptyState(
      icon: Iconsax.repeat,
      title: 'Belum Ada Transaksi Berulang',
      subtitle: 'Otomatis catat transaksi yang terjadi secara rutin',
      actionText: 'Tambah Transaksi Berulang',
      onAction: onAdd,
    );
  }

  /// Network error
  static Widget networkError(VoidCallback onRetry) {
    return EmptyState(
      icon: Iconsax.wifi,
      title: 'Tidak Ada Koneksi',
      subtitle: 'Periksa koneksi internet Anda dan coba lagi',
      actionText: 'Coba Lagi',
      onAction: onRetry,
      iconColor: Colors.orange,
    );
  }

  /// Server error
  static Widget serverError(VoidCallback onRetry) {
    return EmptyState(
      icon: Iconsax.warning_2,
      title: 'Terjadi Kesalahan',
      subtitle: 'Server sedang bermasalah. Coba lagi dalam beberapa saat',
      actionText: 'Coba Lagi',
      onAction: onRetry,
      iconColor: Colors.red,
    );
  }
}
