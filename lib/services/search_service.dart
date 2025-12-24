import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/transaction_model.dart';

/// Service untuk global search functionality
class SearchService {
  final ApiService _apiService = ApiService();

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
      final transactionsData = await _apiService.getTransactions();
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );

      // Filter transactions
      final filtered =
          transactions.where((t) {
            final transaction = t as Map<String, dynamic>;

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
                  if (startDate != null && tDate.isBefore(startDate))
                    return false;
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
              return TransactionModel.fromJson(t as Map<String, dynamic>);
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
      final budgets = await _apiService.getBudgets(
        activeOnly: activeOnly ?? false,
      );

      if (query.isEmpty) {
        return budgets.map((b) => b as Map<String, dynamic>).toList();
      }

      return budgets
          .where((b) {
            final budget = b as Map<String, dynamic>;
            final categoryName =
                (budget['category_name'] ?? '').toString().toLowerCase();
            final searchQuery = query.toLowerCase();
            return categoryName.contains(searchQuery);
          })
          .map((b) => b as Map<String, dynamic>)
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
      final goals = await _apiService.getGoals();

      if (query.isEmpty) {
        return goals.map((g) => g as Map<String, dynamic>).toList();
      }

      return goals
          .where((g) {
            final goal = g as Map<String, dynamic>;
            final name = (goal['name'] ?? '').toString().toLowerCase();
            final searchQuery = query.toLowerCase();
            return name.contains(searchQuery);
          })
          .map((g) => g as Map<String, dynamic>)
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
      final transactionsData = await _apiService.getTransactions();
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );

      // Extract unique descriptions
      final suggestions = <String>{};
      for (var t in transactions) {
        final transaction = t as Map<String, dynamic>;
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
