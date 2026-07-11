import 'package:financial_app/features/debts/domain/repositories/debt_repository_interface.dart';

class DeleteDebtUseCase {
  final DebtRepositoryInterface _repository;
  DeleteDebtUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteDebt(id);
}
