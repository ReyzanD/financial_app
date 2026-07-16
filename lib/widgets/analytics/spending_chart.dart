import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:financial_app/utils/design_tokens.dart';

class SpendingChart extends StatefulWidget {
  final List<dynamic> transactions;

  const SpendingChart({super.key, required this.transactions});

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int _selectedPeriod = 7; // days: 7, 30, or 90

  static const _periodOptions = [7, 30, 90];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dailySpending = _computeDailySpending(now);

    final maxSpending = dailySpending.values.fold<double>(
      0,
      (max, val) => val > max ? val : max,
    );

    // Compute a reasonable max Y from income data when there's no spending
    final avgIncome = widget.transactions
        .where((t) => t['type'] == 'income')
        .map((t) => double.tryParse(t['amount']?.toString() ?? '0') ?? 0)
        .fold<double>(0, (sum, a) => sum + a);
    final reasonableMax = avgIncome > 0 ? avgIncome / 5 : 10000.0;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tren Pengeluaran ($_selectedPeriod Hari Terakhir)',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Period selector chips
          Row(
            children:
                _periodOptions.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? DesignTokens.primaryColor.withValues(
                                    alpha: 0.2,
                                  )
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                isSelected
                                    ? DesignTokens.primaryColor
                                    : DesignTokens.borderDark,
                          ),
                        ),
                        child: Text(
                          '$period Hari',
                          style: GoogleFonts.poppins(
                            color:
                                isSelected
                                    ? DesignTokens.primaryColor
                                    : Colors.white70,
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSpending > 0 ? maxSpending * 1.2 : reasonableMax,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return _buildBottomTitle(value, dailySpending);
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
                    dailySpending.entries.toList().asMap().entries.map((
                      idxEntry,
                    ) {
                      final spending = idxEntry.value.value;
                      final barWidth =
                          _selectedPeriod >= 90
                              ? 4.0
                              : _selectedPeriod >= 30
                              ? 6.0
                              : 16.0;
                      return BarChartGroupData(
                        x: idxEntry.key,
                        barRods: [
                          BarChartRodData(
                            toY: spending,
                            color: DesignTokens.primaryColor,
                            width: barWidth,
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

  /// Compute daily spending for the selected period.
  Map<String, double> _computeDailySpending(DateTime now) {
    final dailySpending = <String, double>{};

    // Initialize all days in the period with 0
    for (int i = _selectedPeriod - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = date.toIso8601String().substring(0, 10);
      dailySpending[dayKey] = 0;
    }

    // Sum up spending per day from transactions
    for (var transaction in widget.transactions) {
      if (transaction['type'] == 'expense') {
        try {
          final dateStr = transaction['date']?.toString() ?? '';
          final transDate = DateTime.parse(dateStr);
          final daysAgo = now.difference(transDate).inDays;

          if (daysAgo >= 0 && daysAgo < _selectedPeriod) {
            final amount =
                double.tryParse(transaction['amount']?.toString() ?? '0') ??
                0.0;
            final dayKey = transDate.toIso8601String().substring(0, 10);
            dailySpending[dayKey] = (dailySpending[dayKey] ?? 0) + amount;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    return dailySpending;
  }

  /// Build bottom axis title, showing labels at smart intervals to avoid crowding.
  Widget _buildBottomTitle(double value, Map<String, double> dailySpending) {
    final entries = dailySpending.entries.toList();
    final idx = value.toInt();
    if (idx < 0 || idx >= entries.length) return const SizedBox();

    // Determine label interval based on period length
    final labelInterval =
        _selectedPeriod >= 90
            ? 14
            : _selectedPeriod >= 30
            ? 5
            : 1;

    // Only show label at interval steps
    if (idx % labelInterval != 0 && idx != entries.length - 1) {
      return const SizedBox();
    }

    final dateStr = entries[idx].key;
    final parts = dateStr.split('-');
    final month = parts[1];
    final day = parts[2];

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
    final monthLabel =
        int.tryParse(month) != null &&
                int.parse(month) >= 1 &&
                int.parse(month) <= 12
            ? months[int.parse(month)]
            : month;

    final label =
        _selectedPeriod >= 90 ? '$monthLabel $day' : '$monthLabel $day';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.grey[500],
          fontSize: _selectedPeriod >= 90 ? 8 : 10,
        ),
      ),
    );
  }
}
