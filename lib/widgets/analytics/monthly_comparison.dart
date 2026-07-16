import 'package:flutter/material.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:financial_app/utils/design_tokens.dart';

class MonthlyComparison extends StatelessWidget {
  final List<dynamic> transactions;

  const MonthlyComparison({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final lastMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final lastMonthYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    double thisMonthSpending = 0;
    double lastMonthSpending = 0;

    // Compute spending for last 6 months for the chart
    final monthlySpending = <String, double>{};
    for (int i = 5; i >= 0; i--) {
      int m = currentMonth - i;
      int y = currentYear;
      if (m < 1) {
        m += 12;
        y -= 1;
      }
      monthlySpending['$y-$m'] = 0.0;
    }

    for (var transaction in transactions) {
      if (transaction['type'] == 'expense') {
        try {
          final dateStr = transaction['date']?.toString() ?? '';
          final transDate = DateTime.parse(dateStr);
          final amount =
              double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
          final key = '${transDate.year}-${transDate.month}';

          if (transDate.year == currentYear &&
              transDate.month == currentMonth) {
            thisMonthSpending += amount;
          } else if (transDate.year == lastMonthYear &&
              transDate.month == lastMonth) {
            lastMonthSpending += amount;
          }

          // Also aggregate into monthly chart data if within range
          if (monthlySpending.containsKey(key)) {
            monthlySpending[key] = (monthlySpending[key] ?? 0) + amount;
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
    final l10n = AppLocalizations.of(context);

    final maxSpending = monthlySpending.values.fold<double>(
      0,
      (max, val) => val > max ? val : max,
    );

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
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
          // Text summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComparisonItem(
                l10n?.this_month ?? 'Bulan Ini',
                'Rp ${(thisMonthSpending / 1000).toStringAsFixed(1)}k',
                DesignTokens.primaryColor,
                null,
              ),
              _buildComparisonItem(
                l10n?.last_month ?? 'Bulan Lalu',
                'Rp ${(lastMonthSpending / 1000).toStringAsFixed(1)}k',
                Colors.grey,
                null,
              ),
              _buildComparisonItem(
                l10n?.change ?? 'Perubahan',
                '${change >= 0 ? "+" : ""}${change.toStringAsFixed(1)}%',
                isIncrease ? Colors.red : Colors.green,
                isIncrease ? Iconsax.arrow_up : Iconsax.arrow_down,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Visual chart: last 6 months spending
          SizedBox(
            height: 180,
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
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final entries = monthlySpending.entries.toList();
                        final idx = value.toInt();
                        if (idx < 0 || idx >= entries.length) {
                          return const SizedBox();
                        }
                        final keyParts = entries[idx].key.split('-');
                        final monthLabel = _monthLabel(int.parse(keyParts[1]));
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            monthLabel,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
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
                    return FlLine(
                      color: DesignTokens.borderDark,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups:
                    monthlySpending.entries.toList().asMap().entries.map((
                      idxEntry,
                    ) {
                      final spending = idxEntry.value.value;
                      final isCurrentMonth =
                          idxEntry.value.key == '$currentYear-$currentMonth';
                      return BarChartGroupData(
                        x: idxEntry.key,
                        barRods: [
                          BarChartRodData(
                            toY: spending,
                            color:
                                isCurrentMonth
                                    ? DesignTokens.primaryColor
                                    : DesignTokens.primaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                            width: 18,
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

  static String _monthLabel(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
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
