import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/services/investment_service.dart';

class InvestmentRepository {
  final InvestmentService _service;
  InvestmentRepository({InvestmentService? service})
    : _service = service ?? getIt<InvestmentService>();

  Future<List<InvestmentModel>> getInvestments({String? type}) =>
      _service.getInvestments(type: type);
  Future<InvestmentModel> addInvestment(InvestmentModel inv) =>
      _service.addInvestment(inv);
  Future<void> deleteInvestment(String id) => _service.deleteInvestment(id);
  Future<Map<String, dynamic>> getPortfolioSummary() =>
      _service.getPortfolioSummary();
}
