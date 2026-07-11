import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:financial_app/utils/design_tokens.dart';

class SpendingChart extends StatelessWidget {
  final List<dynamic> transactions;

  const SpendingChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Calculate daily spending for last 7 days
    final Map<String, double> dailySpending = {};
    final now = DateTime.now();

    // Initialize last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = date.toIso8601String().substring(0, 10);
      dailySpending[dayKey] = 0;
    }

    // Sum up spending per day
    for (var transaction in transactions) {
      if (transaction['type'] == 'expense') {
        try {
          final dateStr = transaction['date']?.toString() ?? '';
          final transDate = DateTime.parse(dateStr);
          final daysAgo = now.difference(transDate).inDays;

          if (daysAgo >= 0 && daysAgo < 7) {
            final amount =
                double.tryParse(transaction['amount']?.toString() ?? '0') ??
                0.0;
            final dayKey = transDate.toIso8601String().substring(0, 10);
            dailySpending[dayKey] =
                (dailySpending[dayKey] ?? 0) + amount;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    final maxSpending = dailySpending.values.fold<double>(
      0,
      (max, val) => val > max ? val : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Pengeluaran (7 Hari Terakhir)',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSpending > 0 ? maxSpending * 1.2 : 100000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final entries = dailySpending.entries.toList();
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox();
                        }
                        // Display short day label (e.g., "Jul 28")
                        final dateStr = entries[idx].key;
                        final parts = dateStr.split('-');
                        final month = parts[1];
                        final day = parts[2];
                        final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                        final monthLabel = int.tryParse(month) != null && int.parse(month) >= 1 && int.parse(month) <= 12
                            ? months[int.parse(month)]
                            : month;
                        return Text(
                          '$monthLabel $day',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: DesignTokens.borderDark, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups:
                    dailySpending.entries.toList().asMap().entries.map((idxEntry) {
                      final spending = idxEntry.value.value;
                      return BarChartGroupData(
                        x: idxEntry.key,
                        barRods: [
                          BarChartRodData(
                            toY: spending,
                            color: DesignTokens.primaryColor,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
