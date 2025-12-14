import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:financial_app/services/logger_service.dart';

class CategoryBreakdown extends StatelessWidget {
  final List<dynamic> transactions;

  const CategoryBreakdown({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    LoggerService.debug(
      'CategoryBreakdown: Processing ${transactions.length} transactions',
    );

    // Calculate category data from all transactions
    final Map<String, Map<String, dynamic>> categoryMap = {};
    double totalAmount = 0;

    // Count all transactions
    for (var transaction in transactions) {
      final amount =
          double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
      final category = transaction['category']?.toString() ?? 'Uncategorized';
      final categoryColor =
          transaction['category_color'] != null
              ? Color(
                int.parse(
                      transaction['category_color'].substring(1, 7),
                      radix: 16,
                    ) +
                    0xFF000000,
              )
              : Colors.grey;

      if (!categoryMap.containsKey(category)) {
        categoryMap[category] = {
          'name': category,
          'amount': 0.0,
          'color': categoryColor,
        };
      }
      categoryMap[category]!['amount'] =
          (categoryMap[category]!['amount'] as double) + amount;
      totalAmount += amount;
    }

    // Convert to list and sort by amount
    final categories =
        categoryMap.values.toList()..sort(
          (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
        );

    // Calculate percentages
    for (var category in categories) {
      final amount = category['amount'] as double;
      category['percentage'] =
          totalAmount > 0 ? (amount / totalAmount * 100).toInt() : 0;
    }

    LoggerService.debug(
      'Found ${categories.length} categories, total amount: $totalAmount',
    );
    if (categories.isNotEmpty) {
      LoggerService.debug('Top category: ${categories.first['name']}');
    }

    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Center(
          child: Text(
            'Belum ada transaksi',
            style: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
        ),
      );
    }

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
            'Breakdown Transaksi per Kategori',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections:
                    categories.take(5).map((category) {
                      final percentage = category['percentage'] as int;
                      return PieChartSectionData(
                        color: category['color'] as Color,
                        value: (category['amount'] as double),
                        title: '$percentage%',
                        radius: 50,
                        titleStyle: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Category List
          ...categories.take(5).map((category) => _buildCategoryItem(category)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Color Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: category['color'] as Color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),

          // Category Name
          Expanded(
            child: Text(
              category['name'] as String,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ),

          // Percentage
          Text(
            '${category['percentage']}%',
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(width: 12),

          // Amount
          Text(
            'Rp ${category['amount'].toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
