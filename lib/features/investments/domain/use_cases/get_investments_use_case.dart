import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/features/investments/domain/repositories/investment_repository_interface.dart';

class GetInvestmentsUseCase {
  final InvestmentRepositoryInterface _r;
  GetInvestmentsUseCase(this._r);
  Future<List<InvestmentModel>> call({String? type}) => _r.getInvestments(type: type);
}
