import 'package:flutter/material.dart';
import 'package:financial_app/features/budgets/domain/entities/budget_entity.dart';
import 'package:financial_app/features/budgets/domain/use_cases/get_budgets_use_case.dart';
import 'package:financial_app/features/budgets/domain/use_cases/create_budget_use_case.dart';
import 'package:financial_app/features/budgets/domain/use_cases/delete_budget_use_case.dart';
import 'package:financial_app/features/budgets/data/repositories/budget_repository.dart';

/// Budget Controller (Presentation Layer)
class BudgetController extends ChangeNotifier {
  final GetBudgetsUseCase _getBudgetsUseCase;
  final CreateBudgetUseCase _createBudgetUseCase;
  final DeleteBudgetUseCase _deleteBudgetUseCase;
  final BudgetRepository _repository;

  BudgetController(
    this._getBudgetsUseCase,
    this._createBudgetUseCase,
    this._deleteBudgetUseCase,
    this._repository,
  );

  List<BudgetEntity> _budgets = [];
  List<BudgetEntity> get budgets => _budgets;

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
        _getBudgetsUseCase(activeOnly: activeOnly),
        _repository.getSummary(activeOnly: activeOnly),
      ]);

      final rawCategories = results[0] as List<Map<String, dynamic>>;
      final budgetEntities = results[1] as List<BudgetEntity>;
      final budgetSummary = results[2] as Map<String, dynamic>;

      // Map categories (expense only)
      final categoryMap = <String, String>{};
      for (final cat in rawCategories) {
        final id = cat['category_id_232143'] ?? cat['id'];
        final name = cat['name_232143'] ?? cat['name'];
        final type = cat['type_232143'] ?? cat['type'];
        if (id != null && name != null && type?.toString().toLowerCase() == 'expense') {
          categoryMap[id.toString()] = name.toString();
        }
      }

      _categories = categoryMap;
      _budgets = budgetEntities;
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
      await _deleteBudgetUseCase(id);
      await loadData(activeOnly: _activeOnly);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Create a budget and refresh
  Future<bool> createBudget(BudgetEntity budget) async {
    try {
      await _createBudgetUseCase(budget);
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
