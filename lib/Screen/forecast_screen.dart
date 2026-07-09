import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:money2/money2.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/expense_predictor.dart';
import 'package:financial_app/services/spending_pattern_analyzer.dart';
import 'package:financial_app/services/budget_predictor.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final ApiService _apiService = ApiService();
  final ExpensePredictor _expensePredictor = ExpensePredictor();
  final SpendingPatternAnalyzer _patternAnalyzer = SpendingPatternAnalyzer();
  final BudgetPredictor _budgetPredictor = BudgetPredictor();

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _expenseForecast = {};
  Map<String, dynamic> _patternAnalysis = {};
  List<Map<String, dynamic>> _budgetRisks = [];
  Map<String, double> _suggestedBudgets = {};
  Map<String, Money> _categoryForecasts = {};

  @override
  void initState() {
    super.initState();
    _loadForecastData();
  }

  Future<void> _loadForecastData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactionsData = await _apiService.getTransactions(limit: 1000);
      final transactions =
          (transactionsData['transactions'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];

      final expenseTx =
          transactions
              .where((t) => (t['type_232143'] ?? t['type']) == 'expense')
              .toList();

      if (expenseTx.isNotEmpty) {
        _expenseForecast = await _expensePredictor.predictNext30Days(
          transactions: _normalizeTransactions(expenseTx),
        );
        _patternAnalysis = _patternAnalyzer.analyzeMultiPeriod(
          transactions: _normalizeTransactions(transactions),
          monthsToAnalyze: 3,
        );
        _budgetRisks = await _budgetPredictor.assessOverspendingRisk();
        _suggestedBudgets = await _budgetPredictor.suggestOptimalBudgets();

        try {
          _categoryForecasts = await _expensePredictor.predictByCategory(
            transactions: _normalizeTransactions(expenseTx),
          );
        } catch (e) {
          LoggerService.warning('Category forecast failed', error: e);
          _categoryForecasts = {};
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading forecast data', error: e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _normalizeTransactions(List<dynamic> txns) {
    return txns.map((t) {
      return {
        'transaction_date': t['transaction_date_232143'] ?? t['date'],
        'date': t['transaction_date_232143'] ?? t['date'],
        'type': t['type_232143'] ?? t['type'],
        'amount': (t['amount_232143'] ?? t['amount'])?.toDouble() ?? 0.0,
        'category_name': t['category_name'] ?? 'Lainnya',
        'description': t['description_232143'] ?? t['description'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Forecast & Prediksi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Iconsax.refresh,
                            color: Colors.white,
                          ),
                          onPressed: _loadForecastData,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: DesignTokens.primaryColor,
                              ),
                            )
                            : _error != null
                            ? _buildErrorState()
                            : RefreshIndicator(
                              onRefresh: _loadForecastData,
                              color: DesignTokens.primaryColor,
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  _buildForecastSummary(),
                                  const SizedBox(height: 20),
                                  _buildSpendingTrendChart(),
                                  const SizedBox(height: 20),
                                  if (_budgetRisks.isNotEmpty)
                                    _buildBudgetRisks(),
                                  if (_budgetRisks.isNotEmpty)
                                    const SizedBox(height: 20),
                                  if (_categoryForecasts.isNotEmpty)
                                    _buildCategoryForecast(),
                                  if (_categoryForecasts.isNotEmpty)
                                    const SizedBox(height: 20),
                                  if (_suggestedBudgets.isNotEmpty)
                                    _buildSuggestedBudgets(),
                                  if (_suggestedBudgets.isNotEmpty)
                                    const SizedBox(height: 20),
                                  if (_patternAnalysis['trends'] != null)
                                    _buildSpendingInsights(),
                                ],
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Forecast',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Butuh data transaksi untuk membuat prediksi',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadForecastData,
              icon: const Icon(Iconsax.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSummary() {
    final forecastAmount = _expenseForecast['forecastAmount'] as double? ?? 0.0;
    final confidence = _expenseForecast['confidence'] as double? ?? 0.0;
    final trend = _expenseForecast['trend'] as String? ?? 'unknown';
    final ci = _expenseForecast['confidence_interval'] as Map? ?? {};
    final lower = ci['upper'] as double? ?? 0.0;
    final upper = ci['upper'] as double? ?? 0.0;

    final trendIcon = switch (trend) {
      'increasing' => Icons.trending_up,
      'decreasing' => Icons.trending_down,
      _ => Icons.trending_flat,
    };
    final trendColor = switch (trend) {
      'increasing' => Colors.red[400],
      'decreasing' => Colors.green[400],
      _ => Colors.grey[400],
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.lamp, color: DesignTokens.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Prediksi 30 Hari Kedepan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rp ${_formatNumber(forecastAmount)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: DesignTokens.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(trendIcon, size: 20, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trend == 'increasing'
                    ? 'Pengeluaran meningkat'
                    : trend == 'decreasing'
                    ? 'Pengeluaran menurun'
                    : 'Pengeluaran stabil',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: trendColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildConfidenceBar(confidence),
          const SizedBox(height: 8),
          Text(
            'Akurasi: ${(confidence * 100).toInt()}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DesignTokens.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'Minimum',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: DesignTokens.textSecondaryDark,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(lower)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  '95% Confidence',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: DesignTokens.textTertiaryDark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'Maksimum',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: DesignTokens.textSecondaryDark,
                      ),
                    ),
                    Text(
                      'Rp ${_formatNumber(upper)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: confidence,
        minHeight: 8,
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          confidence > 0.7
              ? DesignTokens.successColor
              : confidence > 0.5
              ? Colors.orange
              : Colors.red,
        ),
      ),
    );
  }

  Widget _buildSpendingTrendChart() {
    final periodData = _patternAnalysis['period_data'] as Map? ?? {};
    if (periodData.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedMonths = periodData.keys.toList()..sort();
    final expenses =
        sortedMonths.map((m) {
          return (periodData[m]['expense'] as num?)?.toDouble() ?? 0.0;
        }).toList();
    final incomes =
        sortedMonths.map((m) {
          return (periodData[m]['income'] as num?)?.toDouble() ?? 0.0;
        }).toList();

    if (expenses.length < 2) return const SizedBox.shrink();

    final maxVal = [...expenses, ...incomes].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Pengeluaran 3 Bulan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Rp${(value / 1000000).toStringAsFixed(0)}jt',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: DesignTokens.textSecondaryDark,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedMonths.length) {
                          return const SizedBox.shrink();
                        }
                        final monthParts = sortedMonths[value.toInt()].split(
                          '-',
                        );
                        return Text(
                          _monthName(int.tryParse(monthParts[1]) ?? 1),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: DesignTokens.textSecondaryDark,
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
                borderData: FlBorderData(show: false),
                barGroups: List.generate(sortedMonths.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: expenses[i],
                        color: DesignTokens.errorColor,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: incomes[i],
                        color: DesignTokens.successColor,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Pengeluaran', DesignTokens.errorColor),
              const SizedBox(width: 20),
              _buildLegend('Pemasukan', DesignTokens.successColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRisks() {
    final critical =
        _budgetRisks
            .where(
              (r) => r['risk_level'] == 'critical' || r['risk_level'] == 'high',
            )
            .toList();

    if (critical.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignTokens.borderDark),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.tick_circle,
              color: DesignTokens.successColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Semua budget dalam kondisi aman',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.successColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.warning_2, color: DesignTokens.warningColor),
              const SizedBox(width: 8),
              Text(
                'Peringatan Budget',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...critical.map((risk) => _buildBudgetRiskItem(risk)),
        ],
      ),
    );
  }

  Widget _buildBudgetRiskItem(Map<String, dynamic> risk) {
    final category = risk['category_name'] as String? ?? 'Tidak Diketahui';
    final usagePercent = (risk['usage_percent'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = risk['risk_level'] as String? ?? 'unknown';
    final remaining = (risk['remaining'] as num?)?.toDouble() ?? 0.0;
    final exhaustion = risk['exhaustion_prediction'] as Map? ?? {};
    final daysUntil = exhaustion['days_until_exhaustion'] as int?;

    final color = switch (riskLevel) {
      'critical' => DesignTokens.errorColor,
      'high' => DesignTokens.warningColor,
      'medium' => DesignTokens.warningColor,
      _ => DesignTokens.successColor,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${usagePercent.toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: usagePercent / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            daysUntil != null
                ? 'Sisa Rp ${_formatNumber(remaining)} - Habis dalam $daysUntil hari'
                : 'Sisa Rp ${_formatNumber(remaining)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DesignTokens.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryForecast() {
    final sorted =
        _categoryForecasts.entries.toList()
          ..sort((a, b) => b.value.amount.compareTo(a.value.amount));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.category, color: DesignTokens.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Prediksi per Kategori',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...sorted
              .take(8)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        'Rp ${_formatNumber(entry.value.toDouble())}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildSuggestedBudgets() {
    final sorted =
        _suggestedBudgets.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.lamp, color: DesignTokens.warningColor),
              const SizedBox(width: 8),
              Text(
                'Saran Budget Optimal',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Berdasarkan rata-rata pengeluaran + buffer 10%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: DesignTokens.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.warningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DesignTokens.warningColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Rp ${_formatNumber(entry.value.toDouble())}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingInsights() {
    final trends = _patternAnalysis['trends'] as Map? ?? {};
    final dayPatterns = _patternAnalysis['day_of_week_patterns'] as Map? ?? {};
    final merchants = (_patternAnalysis['frequent_merchants'] as List?) ?? [];

    final insights = <Widget>[];

    final expenseTrend = trends['expense_trend'] as String?;
    final expenseChange = trends['expense_change_percent'] as double? ?? 0.0;
    if (expenseTrend != null && expenseTrend != 'insufficient_data') {
      final icon =
          expenseTrend == 'increasing'
              ? Icons.trending_up
              : expenseTrend == 'decreasing'
              ? Icons.trending_down
              : Icons.trending_flat;
      final color =
          expenseTrend == 'increasing'
              ? DesignTokens.errorColor
              : expenseTrend == 'decreasing'
              ? DesignTokens.successColor
              : DesignTokens.textSecondaryDark;
      final text =
          expenseTrend == 'increasing'
              ? 'Pengeluaran meningkat ${expenseChange.abs().toStringAsFixed(1)}% dalam 3 bulan terakhir'
              : expenseTrend == 'decreasing'
              ? 'Pengeluaran menurun ${expenseChange.abs().toStringAsFixed(1)}% - bagus!'
              : 'Pengeluaran stabil dalam 3 bulan terakhir';

      insights.add(_buildInsightCard(icon, color, text));
    }

    final savingsTrend = trends['savings_rate_trend'] as String?;
    if (savingsTrend != null && savingsTrend != 'insufficient_data') {
      final icon =
          savingsTrend == 'improving'
              ? Icons.savings
              : savingsTrend == 'declining'
              ? Icons.warning
              : Icons.trending_flat;
      final color =
          savingsTrend == 'improving'
              ? DesignTokens.successColor
              : savingsTrend == 'declining'
              ? DesignTokens.warningColor
              : DesignTokens.textSecondaryDark;
      final text =
          savingsTrend == 'improving'
              ? 'Tingkat tabungan Anda membaik'
              : savingsTrend == 'declining'
              ? 'Tingkat tabungan menurun, perhatikan pengeluaran'
              : 'Tingkat tabungan stabil';

      insights.add(_buildInsightCard(icon, color, text));
    }

    final peakDay = dayPatterns['peak_day'] as String?;
    if (peakDay != null) {
      insights.add(
        _buildInsightCard(
          Iconsax.calendar,
          DesignTokens.infoColor,
          'Pengeluaran tertinggi pada hari $peakDay',
        ),
      );
    }

    final frequentMerchants =
        merchants.where((m) => (m['frequency'] as int? ?? 0) >= 3).toList();
    if (frequentMerchants.isNotEmpty) {
      final topMerchant = frequentMerchants.first;
      insights.add(
        _buildInsightCard(
          Iconsax.shop,
          DesignTokens.primaryColor,
          'Merchant paling sering: ${topMerchant['merchant']} (${topMerchant['frequency']}x)',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.lamp_charge, color: DesignTokens.infoColor),
              const SizedBox(width: 8),
              Text(
                'Wawasan Pengeluaran',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights,
        ],
      ),
    );
  }

  Widget _buildInsightCard(IconData icon, Color color, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _monthName(int month) {
    const names = [
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
    return names[month];
  }
}
