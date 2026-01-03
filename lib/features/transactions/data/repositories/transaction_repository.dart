import 'package:financial_app/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:financial_app/features/transactions/domain/repositories/transaction_repository_interface.dart';
import 'package:financial_app/services/local_data_service.dart';
import 'package:financial_app/services/logger_service.dart';

class TransactionRepository implements TransactionRepositoryInterface {
  final TransactionRemoteDataSource _dataSource;
  final LocalDataService _localDataService;

  TransactionRepository(this._dataSource, this._localDataService);

  @override
  Future<List<TransactionEntity>> getTransactions({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final transactions = await _dataSource.getTransactions(
        type: type,
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
      );
      return transactions.map((t) => TransactionEntity.fromJson(t)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TransactionEntity> createTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      // 1. Save transaction to database
      final result = await _dataSource.createTransaction(transaction.toJson());
      final savedTransaction = TransactionEntity.fromJson(result);

      LoggerService.info('✅ Transaction created: ${savedTransaction.id}');

      // 2. If it's an EXPENSE, update the budget's spent amount
      if (transaction.type.toLowerCase() == 'expense') {
        await _updateBudgetSpending(
          categoryId: transaction.categoryId,
          amount: transaction.amount,
          transactionDate: transaction.transactionDate,
        );
      }

      return savedTransaction;
    } catch (e) {
      LoggerService.error('Error creating transaction', error: e);
      rethrow;
    }
  }

  /// Update budget spending when an expense is created
  Future<void> _updateBudgetSpending({
    required String categoryId,
    required double amount,
    required DateTime transactionDate,
  }) async {
    try {
      LoggerService.debug(
        '🔄 Updating budget for category: $categoryId, amount: $amount',
      );

      // Get all active budgets for this category
      final budgets = await _localDataService.getBudgetsByCategory(categoryId);

      if (budgets.isEmpty) {
        LoggerService.warning(
          '⚠️ No active budget found for category: $categoryId',
        );
        return;
      }

      // Find the budget that covers this transaction date
      Map<String, dynamic>? matchingBudget;
      for (var budget in budgets) {
        final periodStartStr =
            budget['period_start_232143']?.toString() ??
            budget['period_start']?.toString();
        final periodEndStr =
            budget['period_end_232143']?.toString() ??
            budget['period_end']?.toString();

        if (periodStartStr == null || periodEndStr == null) continue;

        final periodStart = DateTime.parse(periodStartStr);
        final periodEnd = DateTime.parse(periodEndStr);

        // Check if transaction date falls within this budget period
        final transactionDateOnly = DateTime(
          transactionDate.year,
          transactionDate.month,
          transactionDate.day,
        );

        if ((transactionDateOnly.isAfter(periodStart) ||
                transactionDateOnly.isAtSameMomentAs(periodStart)) &&
            (transactionDateOnly.isBefore(periodEnd) ||
                transactionDateOnly.isAtSameMomentAs(periodEnd))) {
          matchingBudget = budget;
          break;
        }
      }

      if (matchingBudget == null) {
        LoggerService.warning(
          '⚠️ No budget period matches transaction date: $transactionDate',
        );
        return;
      }

      // Extract budget values
      final budgetId =
          matchingBudget['budget_id_232143']?.toString() ??
          matchingBudget['budget_id']?.toString() ??
          '';
      final currentSpent =
          ((matchingBudget['spent_amount_232143'] ??
                      matchingBudget['spent_amount'] ??
                      0)
                  as num)
              .toDouble();
      final budgetAmount =
          ((matchingBudget['amount_232143'] ?? matchingBudget['amount'] ?? 0)
                  as num)
              .toDouble();

      // Calculate new amounts
      final newSpentAmount = currentSpent + amount;
      final newRemainingAmount = budgetAmount - newSpentAmount;

      LoggerService.debug(
        '📊 Budget calculation: current=$currentSpent + new=$amount = total=$newSpentAmount',
      );

      // Update the budget
      await _localDataService.updateBudgetSpending(
        budgetId: budgetId,
        spentAmount: newSpentAmount,
        remainingAmount: newRemainingAmount,
      );

      LoggerService.info(
        '✅ Budget spending updated: $currentSpent → $newSpentAmount (added $amount)',
      );
    } catch (e) {
      LoggerService.error('❌ Error updating budget spending', error: e);
      // Don't rethrow - transaction should still succeed
    }
  }

  @override
  Future<TransactionEntity> updateTransaction(
    TransactionEntity transaction,
  ) async {
    try {
      final result = await _dataSource.updateTransaction(
        transaction.id,
        transaction.toJson(),
      );
      return TransactionEntity.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await _dataSource.deleteTransaction(id);
    } catch (e) {
      rethrow;
    }
  }
}
