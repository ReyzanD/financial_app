import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/l10n/app_localizations.dart';

/// Shows a detailed breakdown dialog when an expense would exceed
/// the minimum allowable balance (Rp 25,000).
class InsufficientBalanceDialog {
  static Future<void> show({
    required BuildContext context,
    required double currentBalance,
    required double expenseAmount,
    required double minimumBalance,
  }) {
    final newBalance = currentBalance - expenseAmount;
    final l10n = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.insufficient_balance_title ?? 'Saldo Tidak Cukup',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.transaction_rejected_insufficient_balance ??
                  'Transaksi ditolak! Saldo Anda tidak mencukupi untuk pengeluaran ini.',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  _buildRow(
                    l10n?.available_balance ?? 'Saldo Tersedia',
                    currentBalance,
                    Colors.white70,
                  ),
                  const SizedBox(height: 8),
                  _buildRow(
                    l10n?.minimum_balance ?? 'Saldo Minimum',
                    minimumBalance,
                    Colors.orange[300]!,
                  ),
                  const SizedBox(height: 8),
                  _buildRow(
                    l10n?.expense ?? 'Pengeluaran',
                    expenseAmount,
                    Colors.red[300]!,
                  ),
                  const Divider(color: Colors.grey, height: 20),
                  _buildRow(
                    l10n?.shortage ?? 'Kekurangan',
                    (minimumBalance - newBalance).abs(),
                    Colors.red[400]!,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue[300],
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.add_income_first ??
                          'Tambahkan pemasukan terlebih dahulu atau kurangi jumlah pengeluaran.',
                      style: GoogleFonts.poppins(
                        color: Colors.blue[300],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: Text(
              l10n?.understood ?? 'Mengerti',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          CurrencyFormatter.formatRupiah(amount),
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
