import 'package:financial_app/models/investment_model.dart';

abstract class InvestmentRepositoryInterface {
  Future<List<InvestmentModel>> getInvestments({String? type});
  Future<InvestmentModel> addInvestment(InvestmentModel investment);
  Future<void> deleteInvestment(String id);
  Future<Map<String, dynamic>> getPortfolioSummary();
}
