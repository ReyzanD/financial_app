import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/spending_pattern_analyzer.dart';
import 'package:financial_app/services/goal_forecasting_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/utils/design_tokens.dart';

class FinancialInsightsScreen extends StatefulWidget {
  const FinancialInsightsScreen({super.key});

  @override
  State<FinancialInsightsScreen> createState() => _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen> {
  final ApiService _apiService = ApiService();
  final SpendingPatternAnalyzer _patternAnalyzer = SpendingPatternAnalyzer();
  final GoalForecastingService _goalForecaster = GoalForecastingService();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _transactions = [];
  List<dynamic> _goals = [];
  Map<String, dynamic> _patternAnalysis = {};
  List<Map<String, dynamic>> _insights = [];
  double _healthScore = 0;
  Map<String, dynamic> _spendingTrend = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionsResult = await _apiService.getTransactions(limit: 500);
      final goalsResult = await _apiService.getGoals();

      _transactions = transactionsResult['transactions'] ?? [];
      _goals = goalsResult;

      _patternAnalysis = _patternAnalyzer.analyzeMultiPeriod(
        transactions: _transactions,
        monthsToAnalyze: 3,
      );

      _insights = _generateInsights();
      _healthScore = _calculateHealthScore();
      _spendingTrend = _patternAnalysis['trends'] ?? {};

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading financial insights', error: e);
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorHandlerService.getUserFriendlyMessage(e);
      });
    }
  }

  double _calculateHealthScore() {
    if (_transactions.isEmpty) return 0;

    double score = 50;

    final thisMonth = transactionsThisMonth();
    final lastMonth = transactionsLastMonth();

    double thisMonthExpense = 0;
    double thisMonthIncome = 0;
    for (final t in thisMonth) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      if (type == 'expense') {
        thisMonthExpense += amount;
      } else {
        thisMonthIncome += amount;
      }
    }

    if (thisMonthIncome > 0) {
      final savingsRate = ((thisMonthIncome - thisMonthExpense) / thisMonthIncome) * 100;
      if (savingsRate >= 20) {
        score += 20;
      } else if (savingsRate >= 10) {
        score += 10;
      } else if (savingsRate < 0) {
        score -= 15;
      }
    }

    if (lastMonth.isNotEmpty && thisMonth.length < lastMonth.length * 0.8) {
      score += 5;
    }

    final categorySpending = <String, double>{};
    for (final t in thisMonth) {
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      if (type == 'expense') {
        final category = t['category_name']?.toString() ?? 'Lainnya';
        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }
    }

    if (categorySpending.isNotEmpty) {
      final topCategoryShare = categorySpending.values.reduce((a, b) => a > b ? a : b) /
          categorySpending.values.reduce((a, b) => a + b);
      if (topCategoryShare < 0.5) {
        score += 10;
      }
    }

    if (_goals.isNotEmpty) {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  List<dynamic> transactionsThisMonth() {
    final now = DateTime.now();
    return _transactions.where((t) {
      final dateStr = t['transaction_date']?.toString() ?? t['date']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final date = DateTime.parse(dateStr);
        return date.year == now.year && date.month == now.month;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<dynamic> transactionsLastMonth() {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;
    return _transactions.where((t) {
      final dateStr = t['transaction_date']?.toString() ?? t['date']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final date = DateTime.parse(dateStr);
        return date.year == year && date.month == lastMonth;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _generateInsights() {
    final insights = <Map<String, dynamic>>[];

    if (_transactions.isEmpty) return insights;

    final thisMonth = transactionsThisMonth();
    final lastMonth = transactionsLastMonth();

    double thisExpense = 0;
    double lastExpense = 0;
    double thisIncome = 0;

    for (final t in thisMonth) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      if (type == 'expense') {
        thisExpense += amount;
      } else {
        thisIncome += amount;
      }
    }

    for (final t in lastMonth) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      if (type == 'expense') lastExpense += amount;
    }

    if (lastExpense > 0 && thisExpense > 0) {
      final change = ((thisExpense - lastExpense) / lastExpense) * 100;
      if (change < -10) {
        insights.add({
          'type': 'positive',
          'icon': Iconsax.arrow_down_1,
          'title': 'Pengeluaran menurun!',
          'description': 'Pengeluaran turun ${change.abs().toStringAsFixed(0)}% dibanding bulan lalu. Pertahankan!',
        });
      } else if (change > 15) {
        insights.add({
          'type': 'warning',
          'icon': Iconsax.arrow_up_1,
          'title': 'Pengeluaran meningkat',
          'description': 'Pengeluaran naik ${change.toStringAsFixed(0)}% dibanding bulan lalu. Periksa kategori yang meningkat.',
        });
      }
    }

    if (thisIncome > 0) {
      final savingsRate = ((thisIncome - thisExpense) / thisIncome) * 100;
      if (savingsRate >= 20) {
        insights.add({
          'type': 'positive',
          'icon': Iconsax.safe_home,
          'title': 'Tabungan sehat',
          'description': 'Anda menabung ${savingsRate.toStringAsFixed(0)}% dari pendapatan. Luar biasa!',
        });
      } else if (savingsRate < 0) {
        insights.add({
          'type': 'danger',
          'icon': Iconsax.warning_2,
          'title': 'Pengeluaran melebihi pendapatan',
          'description': 'Defisit ${savingsRate.abs().toStringAsFixed(0)}%. Pertimbangkan untuk mengurangi pengeluaran.',
        });
      }
    }

    final categorySpending = <String, double>{};
    for (final t in thisMonth) {
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      if (type == 'expense') {
        final category = t['category_name']?.toString() ?? 'Lainnya';
        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }
    }

    if (categorySpending.isNotEmpty) {
      final totalExpense = categorySpending.values.reduce((a, b) => a + b);
      final sorted = categorySpending.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topCategory = sorted.first;
      final topShare = (topCategory.value / totalExpense) * 100;

      if (topShare > 40) {
        insights.add({
          'type': 'info',
          'icon': Iconsax.chart,
          'title': '${topCategory.key} mendominasi',
          'description': '${topCategory.key} mengambil ${topShare.toStringAsFixed(0)}% dari total pengeluaran.',
        });
      }
    }

    final weekendSpending = _calculateWeekendSpending();
    if (weekendSpending > 0.3) {
      insights.add({
        'type': 'info',
        'icon': Iconsax.calendar,
        'title': 'Pengeluaran akhir pekan tinggi',
        'description': '${(weekendSpending * 100).toStringAsFixed(0)}% pengeluaran terjadi di akhir pekan.',
      });
    }

    return insights;
  }

  double _calculateWeekendSpending() {
    final thisMonth = transactionsThisMonth();
    if (thisMonth.isEmpty) return 0;

    int weekendCount = 0;
    for (final t in thisMonth) {
      final dateStr = t['transaction_date']?.toString() ?? t['date']?.toString() ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final date = DateTime.parse(dateStr);
        if (date.weekday >= 6) weekendCount++;
      } catch (e) {
        continue;
      }
    }

    return weekendCount / thisMonth.length;
  }

  String _getHealthScoreLabel(double score) {
    if (score >= 80) return 'Sangat Sehat';
    if (score >= 60) return 'Sehat';
    if (score >= 40) return 'Cukup';
    if (score >= 20) return 'Perlu Perbaikan';
    return 'Kritis';
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return DesignTokens.successColor;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return DesignTokens.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surfaceDark,
      appBar: AppBar(
        title: Text(
          'Wawasan Keuangan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: DesignTokens.surfaceDark,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor))
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: DesignTokens.primaryColor,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const OfflineIndicator(),
                      const SizedBox(height: 16),
                      _buildHealthScoreCard(),
                      const SizedBox(height: 16),
                      _buildInsightsCard(),
                      const SizedBox(height: 16),
                      _buildSpendingTrendCard(),
                      const SizedBox(height: 16),
                      _buildGoalForecastsCard(),
                      const SizedBox(height: 16),
                      _buildCategoryDistributionCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: EmptyState(
        icon: Iconsax.warning_2,
        title: 'Gagal memuat wawasan',
        subtitle: _errorMessage ?? 'Terjadi kesalahan',
        actionText: 'Coba Lagi',
        onAction: _loadData,
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getHealthScoreColor(_healthScore).withValues(alpha: 0.2),
            DesignTokens.surfaceDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getHealthScoreColor(_healthScore).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Iconsax.heart, color: _getHealthScoreColor(_healthScore), size: 24),
              const SizedBox(width: 8),
              Text(
                'Skor Kesehatan Keuangan',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _healthScore / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_getHealthScoreColor(_healthScore)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _healthScore.toInt().toString(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getHealthScoreLabel(_healthScore),
                    style: GoogleFonts.poppins(
                      color: _getHealthScoreColor(_healthScore),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5FBF).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.lamp_charge, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Wawasan AI',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_insights.isEmpty)
            Text(
              'Belum ada wawasan yang tersedia. Tambahkan lebih banyak transaksi untuk analisis.',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 13,
              ),
            )
          else
            ..._insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    Color iconColor;
    switch (insight['type']) {
      case 'positive':
        iconColor = DesignTokens.successColor;
        break;
      case 'warning':
        iconColor = Colors.orange;
        break;
      case 'danger':
        iconColor = DesignTokens.errorColor;
        break;
      default:
        iconColor = DesignTokens.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(insight['icon'] as IconData, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['description'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendCard() {
    final trend = _spendingTrend;
    final direction = trend['direction']?.toString() ?? 'stable';
    final percentage = (trend['percentage'] as num?)?.toDouble() ?? 0;

    IconData trendIcon;
    Color trendColor;
    String label;

    switch (direction) {
      case 'increasing':
        trendIcon = Iconsax.arrow_up_1;
        trendColor = DesignTokens.errorColor;
        label = 'Meningkat ${percentage.toStringAsFixed(1)}%';
        break;
      case 'decreasing':
        trendIcon = Iconsax.arrow_down_1;
        trendColor = DesignTokens.successColor;
        label = 'Menurun ${percentage.toStringAsFixed(1)}%';
        break;
      default:
        trendIcon = Iconsax.minus;
        trendColor = Colors.grey;
        label = 'Stabil';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tren Pengeluaran',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: trendColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalForecastsCard() {
    if (_goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          'Belum ada target keuangan. Tambahkan target untuk melihat proyeksi.',
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.flag, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Proyeksi Target',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._goals.take(3).map((goal) {
            final target = (goal['target_amount'] as num?)?.toDouble() ?? 0;
            final current = (goal['current_amount'] as num?)?.toDouble() ?? 0;
            final name = goal['goal_name']?.toString() ?? 'Target';

            final forecast = _goalForecaster.forecastGoalCompletion(
              targetAmount: target,
              currentAmount: current,
              monthlyContribution: (goal['monthly_contribution'] as num?)?.toDouble() ?? 0,
            );

            final progress = target > 0 ? (current / target) * 100 : 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryColor),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${progress.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (forecast['monthsToCompletion'] != null && forecast['monthsToCompletion'] > 0)
                        Text(
                          '~${forecast['monthsToCompletion']} bulan lagi',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  if (forecast['warning'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      forecast['warning'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryDistributionCard() {
    final thisMonth = transactionsThisMonth();
    final categorySpending = <String, double>{};

    for (final t in thisMonth) {
      final type = t['type']?.toString().toLowerCase() ?? 'expense';
      if (type == 'expense') {
        final category = t['category_name']?.toString() ?? 'Lainnya';
        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }
    }

    if (categorySpending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          'Belum ada pengeluaran bulan ini.',
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      );
    }

    final sorted = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.map((e) => e.value).reduce((a, b) => a + b);

    final colors = [
      DesignTokens.primaryColor,
      Colors.blue,
      DesignTokens.successColor,
      Colors.orange,
      Colors.red,
      Colors.cyan,
      Colors.pink,
      Colors.amber,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.chart_2, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Distribusi Kategori',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sorted.take(5).toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final category = entry.value.key;
            final amount = entry.value.value;
            final percentage = (amount / total) * 100;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: colors[idx % colors.length],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(colors[idx % colors.length]),
                    minHeight: 6,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
