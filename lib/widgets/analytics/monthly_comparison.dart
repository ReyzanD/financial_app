import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class MonthlyComparison extends StatelessWidget {
  final List<dynamic> transactions;

  const MonthlyComparison({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Calculate spending for current and last month
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final lastMonthYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    double thisMonthSpending = 0;
    double lastMonthSpending = 0;

    for (var transaction in transactions) {
      if (transaction['type'] == 'expense') {
        try {
          final dateStr = transaction['date']?.toString() ?? '';
          final transDate = DateTime.parse(dateStr);
          final amount =
              double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;

          if (transDate.year == currentYear &&
              transDate.month == currentMonth) {
            thisMonthSpending += amount;
          } else if (transDate.year == lastMonthYear &&
              transDate.month == lastMonth) {
            lastMonthSpending += amount;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    final change =
        lastMonthSpending > 0
            ? ((thisMonthSpending - lastMonthSpending) /
                lastMonthSpending *
                100)
            : 0.0;
    final isIncrease = change > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perbandingan Bulanan',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComparisonItem(
                'Bulan Ini',
                'Rp ${(thisMonthSpending / 1000).toStringAsFixed(1)}k',
                const Color(0xFF8B5FBF),
                null,
              ),
              _buildComparisonItem(
                'Bulan Lalu',
                'Rp ${(lastMonthSpending / 1000).toStringAsFixed(1)}k',
                Colors.grey,
                null,
              ),
              _buildComparisonItem(
                'Perubahan',
                '${change >= 0 ? "+" : ""}${change.toStringAsFixed(1)}%',
                isIncrease ? Colors.red : Colors.green,
                isIncrease ? Iconsax.arrow_up : Iconsax.arrow_down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
    String label,
    String value,
    Color color,
    IconData? icon,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
