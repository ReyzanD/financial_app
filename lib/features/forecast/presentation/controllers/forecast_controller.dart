import 'package:flutter/foundation.dart';
import 'package:money2/money2.dart';
import 'package:financial_app/features/forecast/data/repositories/forecast_repository.dart';
import 'package:financial_app/services/expense_predictor.dart';
import 'package:financial_app/services/spending_pattern_analyzer.dart';
import 'package:financial_app/services/budget_predictor.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/key_normalizer.dart';

class ForecastController extends ChangeNotifier {
  final ForecastRepository _r;
  final ExpensePredictor _expensePredictor;
  final SpendingPatternAnalyzer _patternAnalyzer;
  final BudgetPredictor _budgetPredictor;

  ForecastController({
    required ForecastRepository repository,
    ExpensePredictor? expensePredictor,
    SpendingPatternAnalyzer? patternAnalyzer,
    BudgetPredictor? budgetPredictor,
  }) : _r = repository,
       _expensePredictor = expensePredictor ?? ExpensePredictor(),
       _patternAnalyzer = patternAnalyzer ?? SpendingPatternAnalyzer(),
       _budgetPredictor = budgetPredictor ?? BudgetPredictor();

  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> _expenseForecast = {};
  Map<String, dynamic> _patternAnalysis = {};
  List<Map<String, dynamic>> _budgetRisks = [];
  Map<String, double> _suggestedBudgets = {};
  Map<String, Money> _categoryForecasts = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get expenseForecast => _expenseForecast;
  Map<String, dynamic> get patternAnalysis => _patternAnalysis;
  List<Map<String, dynamic>> get budgetRisks => _budgetRisks;
  Map<String, double> get suggestedBudgets => _suggestedBudgets;
  Map<String, Money> get categoryForecasts => _categoryForecasts;

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final transactionsData = await _r.getTransactions(limit: 1000);
      // Normalize keys early so all downstream code uses clean keys consistently
      final rawTransactions = transactionsData['transactions'] as List<dynamic>? ?? [];
      final transactions = KeyNormalizer.normalizeTransactions(rawTransactions);

      final expenseTx = transactions.where((t) => t['type'] == 'expense').toList();

      if (expenseTx.isNotEmpty) {
        _expenseForecast = await _expensePredictor.predictNext30Days(transactions: expenseTx);
        _patternAnalysis = _patternAnalyzer.analyzeMultiPeriod(transactions: transactions, monthsToAnalyze: 3);
        _budgetRisks = await _budgetPredictor.assessOverspendingRisk();
        _suggestedBudgets = await _budgetPredictor.suggestOptimalBudgets();

        try {
          _categoryForecasts = await _expensePredictor.predictByCategory(transactions: expenseTx);
        } catch (e) {
          LoggerService.warning('Category forecast failed', error: e);
          _categoryForecasts = {};
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Error loading forecast data', error: e);
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadData();
}
