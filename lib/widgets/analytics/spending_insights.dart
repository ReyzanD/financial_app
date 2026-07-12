import 'package:flutter/material.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/design_tokens.dart';

class SpendingInsights extends StatelessWidget {
  final List<dynamic> transactions;
  final Map<String, dynamic> summary;

  const SpendingInsights({
    super.key,
    required this.transactions,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(
          color: DesignTokens.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.lamp_charge,
                color: DesignTokens.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._generateInsights(context),
        ],
      ),
    );
  }

  List<Widget> _generateInsights(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summaries = summary['summary'] ?? {};
    final income =
        (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ?? 0.0;
    final expense =
        (summaries['expense'] as Map<String, dynamic>?)?['total_amount'] ?? 0.0;
    final balance = income - expense;
    final savingsRate = income > 0 ? ((balance / income) * 100) : 0.0;

    List<Widget> insights = [];

    // Savings rate insight
    if (savingsRate < 20 && income > 0) {
      insights.add(
        _buildInsightText(
          '📊 Tingkat tabungan Anda ${savingsRate.toStringAsFixed(1)}%. '
          'Usahakan untuk menabung minimal 20% dari pendapatan.',
        ),
      );
      insights.add(const SizedBox(height: 8));
    } else if (savingsRate >= 20) {
      insights.add(
        _buildInsightText(
          '🎉 Hebat! Anda menabung ${savingsRate.toStringAsFixed(1)}% dari pendapatan. '
          'Pertahankan kebiasaan baik ini!',
        ),
      );
      insights.add(const SizedBox(height: 8));
    }

    // Transaction count insight
    final expenseCount =
        (summaries['expense'] as Map<String, dynamic>?)?['transaction_count'] ??
        0;
    if (expenseCount > 50) {
      insights.add(
        _buildInsightText(
          '💳 Anda melakukan $expenseCount transaksi pengeluaran bulan ini. '
          'Pertimbangkan untuk mengurangi pengeluaran kecil yang sering.',
        ),
      );
      insights.add(const SizedBox(height: 8));
    }

    // Daily average insight
    final avgDailyExpense = expense / 30;
    insights.add(
      Text(
        '📈 Rata-rata pengeluaran harian: Rp ${avgDailyExpense.toStringAsFixed(0)}',
        style: GoogleFonts.poppins(
          color: DesignTokens.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (insights.isEmpty) {
      insights.add(
        _buildInsightText(
          l10n?.add_more_transactions_insights ??
              'Terus kelola keuangan Anda dengan baik! Tambahkan lebih banyak transaksi untuk mendapatkan insights yang lebih berguna.',
        ),
      );
    }

    return insights;
  }

  Widget _buildInsightText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
    );
  }
}
