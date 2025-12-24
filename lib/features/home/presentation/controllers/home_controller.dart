import 'package:flutter/material.dart';
import 'package:financial_app/features/transactions/domain/use_cases/get_transactions_use_case.dart';
import 'package:financial_app/features/budgets/domain/repositories/budget_repository_interface.dart';
import 'package:financial_app/services/ai_recommendations_enhanced_service.dart';

/// Home Controller (Presentation Layer)
class HomeController extends ChangeNotifier {
  final GetTransactionsUseCase _getTransactionsUseCase;
  final BudgetRepositoryInterface _budgetRepository;
  final AIRecommendationsEnhancedService _aiService;

  HomeController(
    this._getTransactionsUseCase,
    this._budgetRepository,
    this._aiService,
  );

  bool _isLoading = false;
  String? _error;
  List<dynamic> _recentTransactions = [];
  List<dynamic> _budgets = [];
  List<Map<String, dynamic>> _aiRecommendations = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get recentTransactions => _recentTransactions;
  List<dynamic> get budgets => _budgets;
  List<Map<String, dynamic>> get aiRecommendations => _aiRecommendations;

  /// Load home data
  Future<void> loadHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load data in parallel
      final transactions = await _getTransactionsUseCase(limit: 10);
      final budgets = await _budgetRepository.getBudgets(activeOnly: true);
      final recommendations = await _aiService.generatePersonalizedRecommendations();

      _recentTransactions = transactions;
      _budgets = budgets;
      _aiRecommendations = recommendations;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh home data
  Future<void> refresh() async {
    await loadHomeData();
  }
}

