import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/investment_data_service.dart';
import 'package:financial_app/models/investment_model.dart';

class InvestmentService {
  final InvestmentDataService _investmentData;

  InvestmentService({InvestmentDataService? investmentData})
    : _investmentData = investmentData ?? getIt<InvestmentDataService>();

  Future<List<InvestmentModel>> getInvestments({String? type}) async {
    return _investmentData.getInvestments(type: type);
  }

  Future<InvestmentModel> addInvestment(InvestmentModel investment) async {
    final created = await _investmentData.addInvestment(investment.toMap());
    return created;
  }

  Future<InvestmentModel> updatePrice(
    String investmentId,
    double newPrice,
  ) async {
    await _investmentData.updateInvestmentPrice(investmentId, newPrice);
    final investments = await getInvestments();
    return investments.firstWhere((i) => i.id == investmentId);
  }

  Future<void> deleteInvestment(String investmentId) async {
    await _investmentData.deleteInvestment(investmentId);
  }

  Future<Map<String, dynamic>> getPortfolioSummary() async {
    return _investmentData.getPortfolioSummary();
  }
}
