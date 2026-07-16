import 'dart:async';
import 'package:financial_app/services/auth_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Settings Repository - delegates to Auth/Data services, adds cross-cutting logic.
class SettingsRepository {
  final AuthService _auth;
  final TransactionDataService _transactionData;
  final BudgetDataService _budgetData;
  final GoalDataService _goalData;

  SettingsRepository({
    AuthService? auth,
    TransactionDataService? transactionData,
    BudgetDataService? budgetData,
    GoalDataService? goalData,
  }) : _auth = auth ?? getIt<AuthService>(),
       _transactionData = transactionData ?? getIt<TransactionDataService>(),
       _budgetData = budgetData ?? getIt<BudgetDataService>(),
       _goalData = goalData ?? getIt<GoalDataService>();

  Future<void> logout() async {
    return await _auth.logout();
  }

  Future<void> deleteAccount() async {
    return await _auth.deleteAccount();
  }

  Future<Map<String, dynamic>> getTransactions({int limit = 10000}) async {
    return await _transactionData.getTransactions(limit: limit);
  }

  /// Full-history export helper — pages through every transaction so exports
  /// never silently truncate at a fixed limit (unlike [getTransactions]).
  Future<List<Map<String, dynamic>>> exportAllTransactions() async {
    return await _transactionData.getAllTransactions();
  }

  Future<List<dynamic>> getBudgets() async {
    return await _budgetData.getBudgets();
  }

  Future<List<dynamic>> getGoals() async {
    return await _goalData.getGoals();
  }
}
