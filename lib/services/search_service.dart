import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Service untuk global search functionality
class SearchService {
  final TransactionDataService _transactionData = getIt<TransactionDataService>();
  final BudgetDataService _budgetData = getIt<BudgetDataService>();
  final GoalDataService _goalData = getIt<GoalDataService>();

  /// Search transactions dengan query
  Future<List<TransactionModel>> searchTransactions({
    required String query,
    String? categoryId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      // Get all transactions
      final transactionsData = await _transactionData.getTransactions();
      final transactions = List<Map<String, dynamic>>.from(
        transactionsData['transactions'] ?? [],
      );

      // Filter transactions
      final filtered = transactions.where((transaction) {
        // Text search
        if (query.isNotEmpty) {
          final description =
              (transaction['description'] ?? '').toString().toLowerCase();
          final categoryName =
              (transaction['category_name'] ?? '').toString().toLowerCase();
          final searchQuery = query.toLowerCase();

          if (!description.contains(searchQuery) &&
              !categoryName.contains(searchQuery)) {
            return false;
          }
        }

        // Category filter
        if (categoryId != null) {
          final tCategoryId = transaction['category_id']?.toString();
          if (tCategoryId != categoryId) return false;
        }

        // Type filter
        if (type != null) {
          final tType = transaction['type']?.toString();
          if (tType != type) return false;
        }

        // Date range filter
        if (startDate != null || endDate != null) {
          final tDateStr = transaction['transaction_date']?.toString();
          if (tDateStr != null) {
            try {
              final tDate = DateTime.parse(tDateStr);
              if (startDate != null && tDate.isBefore(startDate)) {
                return false;
              }
              if (endDate != null && tDate.isAfter(endDate)) return false;
            } catch (e) {
              LoggerService.error('Error parsing date', error: e);
            }
          }
        }

        // Amount range filter
        if (minAmount != null || maxAmount != null) {
          final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
          if (minAmount != null && amount < minAmount) return false;
          if (maxAmount != null && amount > maxAmount) return false;
        }

        return true;
      }).toList();

      // Convert to TransactionModel
      return filtered
          .map((t) {
            try {
              return TransactionModel.fromJson(t);
            } catch (e) {
              LoggerService.error('Error converting transaction', error: e);
              return null;
            }
          })
          .whereType<TransactionModel>()
          .toList();
    } catch (e) {
      LoggerService.error('Error searching transactions', error: e);
      return [];
    }
  }

  /// Search budgets
  Future<List<Map<String, dynamic>>> searchBudgets({
    required String query,
    bool? activeOnly,
  }) async {
    try {
      final budgetModels = await _budgetData.getBudgets(
        activeOnly: activeOnly ?? false,
      );
      final budgets = budgetModels.map((b) => b.toMap()).toList();

      if (query.isEmpty) {
        return budgets;
      }

      return budgets
          .where((budget) {
            final categoryName =
                (budget['category_name'] ?? '').toString().toLowerCase();
            final searchQuery = query.toLowerCase();
            return categoryName.contains(searchQuery);
          })
          .toList();
    } catch (e) {
      LoggerService.error('Error searching budgets', error: e);
      return [];
    }
  }

  /// Search goals
  Future<List<Map<String, dynamic>>> searchGoals({
    required String query,
  }) async {
    try {
      final goalModels = await _goalData.getGoals();
      final goals = goalModels.map((g) => g.toMap()).toList();

      if (query.isEmpty) {
        return goals;
      }

      return goals
          .where((goal) {
            final name = (goal['name'] ?? '').toString().toLowerCase();
            final searchQuery = query.toLowerCase();
            return name.contains(searchQuery);
          })
          .toList();
    } catch (e) {
      LoggerService.error('Error searching goals', error: e);
      return [];
    }
  }

  /// Global search across all entities
  Future<Map<String, dynamic>> globalSearch({
    required String query,
    List<String>? entityTypes, // ['transactions', 'budgets', 'goals']
  }) async {
    try {
      final results = <String, dynamic>{};
      final types = entityTypes ?? ['transactions', 'budgets', 'goals'];

      if (types.contains('transactions')) {
        final transactions = await searchTransactions(query: query);
        results['transactions'] = transactions;
      }

      if (types.contains('budgets')) {
        final budgets = await searchBudgets(query: query);
        results['budgets'] = budgets;
      }

      if (types.contains('goals')) {
        final goals = await searchGoals(query: query);
        results['goals'] = goals;
      }

      return results;
    } catch (e) {
      LoggerService.error('Error in global search', error: e);
      return {};
    }
  }

  /// Get search suggestions berdasarkan recent searches
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      // Get recent transactions untuk suggestions
      final transactionsData = await _transactionData.getTransactions();
      final transactions = List<Map<String, dynamic>>.from(
        transactionsData['transactions'] ?? [],
      );

      // Extract unique descriptions
      final suggestions = <String>{};
      for (var transaction in transactions) {
        final description = (transaction['description'] ?? '').toString();
        if (description.isNotEmpty &&
            description.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(description);
        }
      }

      return suggestions.take(5).toList();
    } catch (e) {
      LoggerService.error('Error getting search suggestions', error: e);
      return [];
    }
  }
}
