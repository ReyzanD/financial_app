import 'package:flutter/foundation.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/features/insights/domain/repositories/insights_repository_interface.dart';
import 'package:financial_app/services/spending_pattern_analyzer.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/key_normalizer.dart';
import 'package:flutter/material.dart';

class InsightsController extends ChangeNotifier {
  final InsightsRepositoryInterface _r;
  final SpendingPatternAnalyzer _analyzer;

  InsightsController({
    required InsightsRepositoryInterface repository,
    SpendingPatternAnalyzer? analyzer,
  }) : _r = repository,
       _analyzer = analyzer ?? SpendingPatternAnalyzer();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _transactions = [];
  List<dynamic> _goals = [];
  Map<String, dynamic> _patternAnalysis = {};
  List<Map<String, dynamic>> _insights = [];
  double _healthScore = 0;
  Map<String, dynamic> _spendingTrend = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get transactions => _transactions;
  List<dynamic> get goals => _goals;
  Map<String, dynamic> get patternAnalysis => _patternAnalysis;
  List<Map<String, dynamic>> get insights => _insights;
  double get healthScore => _healthScore;
  Map<String, dynamic> get spendingTrend => _spendingTrend;

  // Normalization now uses shared KeyNormalizer.normalizeTransactions() from
  // lib/utils/key_normalizer.dart — the controller-level _normalizeTransactions
  // has been removed to eliminate duplication.

  List<dynamic> _transactionsThisMonth() {
    final now = DateTime.now();
    return _transactions.where((t) {
      final dateStr =
          t['transaction_date']?.toString() ?? t['date']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final date = DateTime.parse(dateStr);
        return date.year == now.year && date.month == now.month;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<dynamic> _transactionsLastMonth() {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;
    return _transactions.where((t) {
      final dateStr =
          t['transaction_date']?.toString() ?? t['date']?.toString() ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final date = DateTime.parse(dateStr);
        return date.year == year && date.month == lastMonth;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  void _calculateHealthScore() {
    if (_transactions.isEmpty) {
      _healthScore = 0;
      return;
    }

    double score = 50;
    final thisMonth = _transactionsThisMonth();
    final lastMonth = _transactionsLastMonth();

    double thisMonthExpense = 0, thisMonthIncome = 0;
    for (final t in thisMonth) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      if ((t['type']?.toString().toLowerCase() ?? 'expense') == 'expense') {
        thisMonthExpense += amount;
      } else {
        thisMonthIncome += amount;
      }
    }

    if (thisMonthIncome > 0) {
      final savingsRate =
          ((thisMonthIncome - thisMonthExpense) / thisMonthIncome) * 100;
      if (savingsRate >= 20)
        score += 20;
      else if (savingsRate >= 10)
        score += 10;
      else if (savingsRate < 0)
        score -= 15;
    }

    if (lastMonth.isNotEmpty && thisMonth.length < lastMonth.length * 0.8)
      score += 5;

    final categorySpending = <String, double>{};
    for (final t in thisMonth) {
      if ((t['type']?.toString().toLowerCase() ?? 'expense') == 'expense') {
        final category = t['category_name']?.toString() ?? 'Lainnya';
        categorySpending[category] =
            (categorySpending[category] ?? 0) +
            ((t['amount'] as num?)?.toDouble() ?? 0);
      }
    }
    if (categorySpending.isNotEmpty) {
      final vals = categorySpending.values.toList();
      final topShare =
          vals.reduce((a, b) => a > b ? a : b) / vals.reduce((a, b) => a + b);
      if (topShare < 0.5) score += 10;
    }

    if (_goals.isNotEmpty) score += 5;
    _healthScore = score.clamp(0, 100);
  }

  double _calculateWeekendSpending() {
    final thisMonth = _transactionsThisMonth();
    if (thisMonth.isEmpty) return 0;
    int weekendCount = 0;
    for (final t in thisMonth) {
      final dateStr =
          t['transaction_date']?.toString() ?? t['date']?.toString() ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final date = DateTime.parse(dateStr);
        if (date.weekday >= 6) weekendCount++;
      } catch (_) {
        continue;
      }
    }
    return weekendCount / thisMonth.length;
  }

  void _generateInsights() {
    _insights = [];
    if (_transactions.isEmpty) return;

    final thisMonth = _transactionsThisMonth();
    final lastMonth = _transactionsLastMonth();

    double thisExpense = 0, lastExpense = 0, thisIncome = 0;
    for (final t in thisMonth) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0;
      if ((t['type']?.toString().toLowerCase() ?? 'expense') == 'expense')
        thisExpense += amt;
      else
        thisIncome += amt;
    }
    for (final t in lastMonth) {
      if ((t['type']?.toString().toLowerCase() ?? 'expense') == 'expense')
        lastExpense += (t['amount'] as num?)?.toDouble() ?? 0;
    }

    if (lastExpense > 0 && thisExpense > 0) {
      final change = ((thisExpense - lastExpense) / lastExpense) * 100;
      if (change < -10) {
        // TODO: Localize - move to screen layer or inject AppLocalizations
        _insights.add({
          'type': 'positive',
          'icon': Iconsax.arrow_down_1,
          'title': 'Pengeluaran menurun!',
          'description':
              'Pengeluaran turun ${change.abs().toStringAsFixed(0)}% dibanding bulan lalu. Pertahankan!',
        });
      } else if (change > 15) {
        // TODO: Localize - move to screen layer or inject AppLocalizations
        _insights.add({
          'type': 'warning',
          'icon': Iconsax.arrow_up_1,
          'title': 'Pengeluaran meningkat',
          'description':
              'Pengeluaran naik ${change.toStringAsFixed(0)}% dibanding bulan lalu. Periksa kategori yang meningkat.',
        });
      }
    }

    if (thisIncome > 0) {
      final savingsRate = ((thisIncome - thisExpense) / thisIncome) * 100;
      if (savingsRate >= 20) {
        // TODO: Localize - move to screen layer or inject AppLocalizations
        _insights.add({
          'type': 'positive',
          'icon': Iconsax.safe_home,
          'title': 'Tabungan sehat',
          'description':
              'Anda menabung ${savingsRate.toStringAsFixed(0)}% dari pendapatan. Luar biasa!',
        });
      } else if (savingsRate < 0) {
        // TODO: Localize - move to screen layer or inject AppLocalizations
        _insights.add({
          'type': 'danger',
          'icon': Iconsax.warning_2,
          'title': 'Pengeluaran melebihi pendapatan',
          'description':
              'Defisit ${savingsRate.abs().toStringAsFixed(0)}%. Pertimbangkan untuk mengurangi pengeluaran.',
        });
      }
    }

    final categorySpending = <String, double>{};
    for (final t in thisMonth) {
      if ((t['type']?.toString().toLowerCase() ?? 'expense') == 'expense') {
        final cat = t['category_name']?.toString() ?? 'Lainnya';
        categorySpending[cat] =
            (categorySpending[cat] ?? 0) +
            ((t['amount'] as num?)?.toDouble() ?? 0);
      }
    }
    if (categorySpending.isNotEmpty) {
      final total = categorySpending.values.reduce((a, b) => a + b);
      final sorted =
          categorySpending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final share = (top.value / total) * 100;
      if (share > 40) {
        // TODO: Localize - move to screen layer or inject AppLocalizations
        _insights.add({
          'type': 'info',
          'icon': Iconsax.chart,
          'title': '${top.key} mendominasi',
          'description':
              '${top.key} mengambil ${share.toStringAsFixed(0)}% dari total pengeluaran.',
        });
      }
    }

    final weekendSpending = _calculateWeekendSpending();
    if (weekendSpending > 0.3) {
      // TODO: Localize - move to screen layer or inject AppLocalizations
      _insights.add({
        'type': 'info',
        'icon': Iconsax.calendar,
        'title': 'Pengeluaran akhir pekan tinggi',
        'description':
            '${(weekendSpending * 100).toStringAsFixed(0)}% pengeluaran terjadi di akhir pekan.',
      });
    }
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final transactionsResult = await _r.getTransactions(limit: 500);
      _goals = await _r.getGoals();

      final rawTransactions =
          (transactionsResult['transactions'] as List?) ?? [];
      _transactions = KeyNormalizer.normalizeTransactions(rawTransactions);

      _patternAnalysis = _analyzer.analyzeMultiPeriod(
        transactions: _transactions,
        monthsToAnalyze: 3,
      );
      _generateInsights();
      _calculateHealthScore();
      _spendingTrend = _patternAnalysis['trends'] ?? {};

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Error loading financial insights', error: e);
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadData();

  String getHealthScoreLabel() {
    // TODO: Localize - move to screen layer or inject AppLocalizations
    if (_healthScore >= 80) return 'Sangat Sehat';
    // TODO: Localize - move to screen layer or inject AppLocalizations
    if (_healthScore >= 60) return 'Sehat';
    // TODO: Localize - move to screen layer or inject AppLocalizations
    if (_healthScore >= 40) return 'Cukup';
    // TODO: Localize - move to screen layer or inject AppLocalizations
    if (_healthScore >= 20) return 'Perlu Perbaikan';
    // TODO: Localize - move to screen layer or inject AppLocalizations
    return 'Kritis';
  }

  Color getHealthScoreColor() {
    if (_healthScore >= 80) return DesignTokens.successColor;
    if (_healthScore >= 60) return Colors.blue;
    if (_healthScore >= 40) return Colors.orange;
    return DesignTokens.errorColor;
  }
}
