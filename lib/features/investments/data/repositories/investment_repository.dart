import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/services/investment_service.dart';
import 'package:financial_app/features/investments/domain/repositories/investment_repository_interface.dart';

class InvestmentRepository implements InvestmentRepositoryInterface {
  final InvestmentService _service;
  InvestmentRepository({InvestmentService? service})
      : _service = service ?? InvestmentService();

  @override Future<List<InvestmentModel>> getInvestments({String? type}) => _service.getInvestments(type: type);
  @override Future<InvestmentModel> addInvestment(InvestmentModel inv) => _service.addInvestment(inv);
  @override Future<void> deleteInvestment(String id) => _service.deleteInvestment(id);
  @override Future<Map<String, dynamic>> getPortfolioSummary() => _service.getPortfolioSummary();
}
