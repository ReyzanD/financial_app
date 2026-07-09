import 'package:financial_app/services/local_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/feature_models.dart';

class InvestmentService {
  final LocalDataService _localData;

  InvestmentService({LocalDataService? localData})
    : _localData = localData ?? LocalDataService();

  Future<List<InvestmentModel>> getInvestments({String? type}) async {
    try {
      final investmentsData = await _localData.getInvestments(type: type);
      return investmentsData.map((i) => InvestmentModel.fromMap(i)).toList();
    } catch (e) {
      LoggerService.error('Error getting investments', error: e);
      return [];
    }
  }

  Future<InvestmentModel> addInvestment(InvestmentModel investment) async {
    try {
      final result = await _localData.addInvestment(investment.toMap());
      final created = InvestmentModel.fromMap(
        result['investment'] as Map<String, dynamic>,
      );
      LoggerService.success('Investment added: ${created.name}');
      return created;
    } catch (e) {
      LoggerService.error('Error adding investment', error: e);
      rethrow;
    }
  }

  Future<InvestmentModel> updatePrice(
    String investmentId,
    double newPrice,
  ) async {
    try {
      await _localData.updateInvestmentPrice(investmentId, newPrice);
      final investments = await getInvestments();
      return investments.firstWhere((i) => i.id == investmentId);
    } catch (e) {
      LoggerService.error('Error updating price', error: e);
      rethrow;
    }
  }

  Future<void> deleteInvestment(String investmentId) async {
    try {
      await _localData.deleteInvestment(investmentId);
      LoggerService.success('Investment deleted');
    } catch (e) {
      LoggerService.error('Error deleting investment', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPortfolioSummary() async {
    try {
      return await _localData.getPortfolioSummary();
    } catch (e) {
      LoggerService.error('Error getting portfolio summary', error: e);
      return {};
    }
  }
}
