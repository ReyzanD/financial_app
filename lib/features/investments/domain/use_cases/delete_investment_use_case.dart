import 'package:financial_app/features/investments/domain/repositories/investment_repository_interface.dart';

class DeleteInvestmentUseCase {
  final InvestmentRepositoryInterface _r;
  DeleteInvestmentUseCase(this._r);
  Future<void> call(String id) => _r.deleteInvestment(id);
}
