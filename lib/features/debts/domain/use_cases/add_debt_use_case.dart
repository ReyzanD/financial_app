import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/features/debts/domain/repositories/debt_repository_interface.dart';

class AddDebtUseCase {
  final DebtRepositoryInterface _repository;
  AddDebtUseCase(this._repository);

  Future<DebtModel> call(DebtModel debt) => _repository.addDebt(debt);
}
