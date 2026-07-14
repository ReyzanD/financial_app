import 'package:flutter/material.dart';
import 'package:financial_app/models/budget_model.dart';
import 'package:financial_app/models/category_model.dart';
import 'package:financial_app/features/budgets/data/repositories/budget_repository.dart';

/// Budget Controller (Presentation Layer)
class BudgetController extends ChangeNotifier {
  final BudgetRepository _repository;

  BudgetController(this._repository);

  List<BudgetModel> _budgets = [];
  List<BudgetModel> get budgets => _budgets;

  Map<String, String> _categories = {};
  Map<String, String> get categories => _categories;

  Map<String, dynamic>? _summary;
  Map<String, dynamic> get summary => _summary ?? {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _activeOnly = true;
  bool get activeOnly => _activeOnly;

  /// Load all budget data (budgets, categories, summary)
  Future<void> loadData({bool activeOnly = true}) async {
    _activeOnly = activeOnly;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getBudgets(activeOnly: activeOnly),
        _repository.getSummary(activeOnly: activeOnly),
      ]);

      final rawCategories = results[0] as List<CategoryModel>;
      final budgetModels = results[1] as List<BudgetModel>;
      final budgetSummary = results[2] as Map<String, dynamic>;

      // Map categories (expense only)
      final categoryMap = <String, String>{};
      for (final cat in rawCategories) {
        if (cat.type?.toString().toLowerCase() == 'expense') {
          categoryMap[cat.id] = cat.name;
        }
      }

      _categories = categoryMap;
      _budgets = budgetModels;
      _summary = budgetSummary;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle active-only filter
  Future<void> toggleActiveFilter() async {
    await loadData(activeOnly: !_activeOnly);
  }

  /// Delete a budget and refresh
  Future<void> deleteBudget(String id) async {
    try {
      await _repository.deleteBudget(id);
      await loadData(activeOnly: _activeOnly);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create a budget from a model and refresh
  Future<bool> createBudget(BudgetModel budget) async {
    try {
      await _repository.createBudget(budget);
      await loadData(activeOnly: _activeOnly);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a budget from raw data map (for legacy widget support)
  Future<bool> updateBudgetFromMap(String id, Map<String, dynamic> data) async {
    try {
      data['id'] = id;
      final model = BudgetModel.fromMap(data);
      await _repository.updateBudget(model);
      await loadData(activeOnly: _activeOnly);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadData(activeOnly: _activeOnly);
  }
}
