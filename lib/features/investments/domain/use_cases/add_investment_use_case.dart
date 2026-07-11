import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/features/investments/domain/repositories/investment_repository_interface.dart';

class AddInvestmentUseCase {
  final InvestmentRepositoryInterface _r;
  AddInvestmentUseCase(this._r);
  Future<InvestmentModel> call(InvestmentModel inv) => _r.addInvestment(inv);
}
