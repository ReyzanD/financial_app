import 'package:financial_app/features/transactions/domain/repositories/transaction_repository_interface.dart';

/// Use Case: Delete Transaction
class DeleteTransactionUseCase {
  final TransactionRepositoryInterface _repository;

  DeleteTransactionUseCase(this._repository);

  Future<void> call(String id) async {
    if (id.isEmpty) {
      throw Exception('Transaction ID is required');
    }
    await _repository.deleteTransaction(id);
  }
}
