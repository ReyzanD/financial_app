import 'package:flutter/foundation.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/budget_recommendation_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class AIBudgetController extends ChangeNotifier {
  final ApiService _api = getIt<ApiService>();
  final BudgetRecommendationService _budgetService = getIt<BudgetRecommendationService>();

  bool _isLoading = true;
  bool _isApplying = false;
  Map<String, dynamic>? _recommendation;
  final Map<String, double> _editedPercentages = {};
  double? _editedIncome;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isApplying => _isApplying;
  Map<String, dynamic>? get recommendation => _recommendation;
  Map<String, double> get editedPercentages => _editedPercentages;
  double? get editedIncome => _editedIncome;
  String? get error => _error;

  Future<void> loadRecommendation() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _recommendation = await _budgetService.generateRecommendation();
    } catch (e) {
      LoggerService.error('Error loading budget recommendation', error: e);
      _error = ErrorHandlerService.getUserFriendlyMessage(e);
    } finally { _isLoading = false; notifyListeners(); }
  }

  void setEditedIncome(double? income) { _editedIncome = income; notifyListeners(); }

  void setEditedPercentage(String category, double pct) { _editedPercentages[category] = pct; notifyListeners(); }

  Future<void> applyRecommendation() async {
    if (_recommendation == null) return;
    _isApplying = true; notifyListeners();

    try {
      final categories = await _api.getCategories();
      final existingBudgets = await _api.getBudgets();
      final income = _editedIncome ?? (_recommendation!['total_income'] as num).toDouble();
      final recCategories = _recommendation!['categories'] as List;

      int created = 0, updated = 0;
      for (var rec in recCategories) {
        final catName = rec['name'] as String;
        final pct = _editedPercentages[catName] ?? ((rec['percentage'] as num?)?.toDouble() ?? 0.0);
        final amount = income * (pct / 100);
        final match = _findMatchingCategory(categories, catName);
        if (match == null) { continue; }
        final categoryId = match['category_id_232143'] ?? match['id'];
        if (categoryId == null) { continue; }
        final now = DateTime.now();
        final ps = DateTime(now.year, now.month, 1);
        final pe = DateTime(now.year, now.month + 1, 0);
        final existing = _findExistingBudget(existingBudgets, categoryId, ps, pe);
        if (existing != null) {
          final bid = existing['budget_id_232143'] ?? existing['id'];
          await _api.updateBudget(bid, {'amount': amount, 'period': 'monthly', 'period_start': ps.toIso8601String().split('T')[0], 'period_end': pe.toIso8601String().split('T')[0], 'alert_threshold': 80});
          updated++;
        } else {
          await _api.createBudget({'category_id': categoryId, 'amount': amount, 'period': 'monthly', 'period_start': ps.toIso8601String().split('T')[0], 'period_end': pe.toIso8601String().split('T')[0], 'alert_threshold': 80});
          created++;
        }
      }
      _isApplying = false; notifyListeners();
      final total = created + updated;
      if (total > 0) {
          _error = null;
      }
    } catch (e) {
      LoggerService.error('Error applying recommendations', error: e);
      _error = ErrorHandlerService.getUserFriendlyMessage(e);
      _isApplying = false; notifyListeners();
    }
  }

  Map<String, dynamic>? _findMatchingCategory(List categories, String name) {
    final mappings = {'Kebutuhan Pokok': ['Makanan', 'Food', 'Groceries'], 'Dana Darurat': ['Tabungan', 'Savings', 'Emergency'], 'Tabungan & Investasi': ['Investasi', 'Investment', 'Savings'], 'Hiburan & Lifestyle': ['Hiburan', 'Entertainment', 'Lifestyle'], 'Pendidikan & Pengembangan': ['Pendidikan', 'Education', 'Learning'], 'Amal & Sedekah': ['Amal', 'Charity', 'Donation']};
    final possible = mappings[name] ?? [name];
    for (var c in categories) {
      final cn = (c['name_232143'] ?? c['name'] ?? '').toString().toLowerCase();
      for (var p in possible) { if (cn.contains(p.toLowerCase())) return c; }
    }
    return null;
  }

  Map<String, dynamic>? _findExistingBudget(List budgets, String catId, DateTime ps, DateTime pe) {
    for (var b in budgets) {
      if ((b['category_id_232143'] ?? b['category_id']) == catId) {
        return b;
      }
    }
    return null;
  }
}
