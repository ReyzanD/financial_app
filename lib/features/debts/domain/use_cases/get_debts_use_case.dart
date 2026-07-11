import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/features/debts/domain/repositories/debt_repository_interface.dart';

class GetDebtsUseCase {
  final DebtRepositoryInterface _repository;
  GetDebtsUseCase(this._repository);

  Future<List<DebtModel>> call({bool activeOnly = true}) =>
      _repository.getDebts(activeOnly: activeOnly);
}
