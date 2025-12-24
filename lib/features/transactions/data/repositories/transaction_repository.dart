import 'package:financial_app/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:financial_app/features/transactions/domain/repositories/transaction_repository_interface.dart';

/// Transaction Repository Implementation (Data Layer)
class TransactionRepository implements TransactionRepositoryInterface {
  final TransactionRemoteDataSource _dataSource;

  TransactionRepository(this._dataSource);

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
  Future<TransactionEntity> createTransaction(TransactionEntity transaction) async {
    try {
      final result = await _dataSource.createTransaction(transaction.toJson());
      return TransactionEntity.fromJson(result);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<TransactionEntity> updateTransaction(TransactionEntity transaction) async {
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

