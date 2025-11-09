import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.lamp_charge,
                color: const Color(0xFF8B5FBF),
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
          ..._generateInsights(),
        ],
      ),
    );
  }

  List<Widget> _generateInsights() {
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
          color: const Color(0xFF8B5FBF),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (insights.isEmpty) {
      insights.add(
        _buildInsightText(
          'Terus kelola keuangan Anda dengan baik! '
          'Tambahkan lebih banyak transaksi untuk mendapatkan insights yang lebih berguna.',
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
