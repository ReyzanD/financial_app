import 'package:financial_app/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:financial_app/features/transactions/domain/repositories/transaction_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';

class TransactionRepository implements TransactionRepositoryInterface {
  final TransactionRemoteDataSource _dataSource;
  final BudgetDataService _budgetData;

  TransactionRepository(this._dataSource, this._budgetData);

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

  /// Update budget spending when an expense is created.
  /// Delegates to BudgetDataService which now owns this logic.
  Future<void> _updateBudgetSpending({
    required String categoryId,
    required double amount,
    required DateTime transactionDate,
  }) async {
    try {
      await _budgetData.updateBudgetForExpense(
        categoryId: categoryId,
        amount: amount,
        transactionDate: transactionDate,
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
