import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';

/// Transaction Repository Interface (Domain Layer)
abstract class TransactionRepositoryInterface {
  Future<List<TransactionEntity>> getTransactions({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });

  Future<TransactionEntity> createTransaction(TransactionEntity transaction);
  Future<TransactionEntity> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
}

