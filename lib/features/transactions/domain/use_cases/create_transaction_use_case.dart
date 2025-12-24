import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:financial_app/features/transactions/domain/repositories/transaction_repository_interface.dart';

/// Use Case: Create Transaction
class CreateTransactionUseCase {
  final TransactionRepositoryInterface _repository;

  CreateTransactionUseCase(this._repository);

  Future<TransactionEntity> call(TransactionEntity transaction) async {
    // Business logic validation
    if (transaction.amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }
    
    if (transaction.categoryId.isEmpty) {
      throw Exception('Category is required');
    }

    return await _repository.createTransaction(transaction);
  }
}

