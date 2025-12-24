import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:financial_app/features/transactions/domain/repositories/transaction_repository_interface.dart';

/// Use Case: Get Transactions
class GetTransactionsUseCase {
  final TransactionRepositoryInterface _repository;

  GetTransactionsUseCase(this._repository);

  Future<List<TransactionEntity>> call({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    int limit = 100,
  }) async {
    return await _repository.getTransactions(
      type: type,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
    );
  }
}

