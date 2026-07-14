import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/api_service.dart';

class ObligationService {
  final ApiService _apiService;
  ObligationService({ApiService? apiService})
    : _apiService = apiService ?? getIt<ApiService>();

  Future<Map<String, dynamic>> getObligationsSummary() async {
    try {
      return await _apiService.getObligationsSummary();
    } catch (e) {
      return {'monthlyTotal': 0.0, 'totalDebt': 0.0, 'obligationsCount': 0};
    }
  }

  Future<List<FinancialObligation>> getUpcomingObligations({
    int days = 7,
  }) async {
    try {
      return await _apiService.getUpcomingObligations(days: days);
    } catch (e) {
      return [];
    }
  }

  Future<List<FinancialObligation>> getObligations({String? type}) async {
    try {
      return await _apiService.getObligations(type: type);
    } catch (e) {
      return [];
    }
  }

  Future<DebtSummary> getDebtSummary() async {
    try {
      final debts = await _apiService.getObligations(type: 'debt');

      double totalDebt = 0.0;
      double monthlyPayments = 0.0;

      for (var debt in debts) {
        totalDebt += debt.currentBalance ?? 0.0;
        monthlyPayments += debt.monthlyAmount;
      }

      return DebtSummary(
        debts: debts,
        totalDebt: totalDebt,
        monthlyPayments: monthlyPayments,
      );
    } catch (e) {
      return DebtSummary(debts: [], totalDebt: 0.0, monthlyPayments: 0.0);
    }
  }

  Future<List<FinancialObligation>> getSubscriptions() async {
    try {
      return await _apiService.getObligations(type: 'subscription');
    } catch (e) {
      return [];
    }
  }

  Future<String> createObligation(Map<String, dynamic> obligationData) async {
    final response = await _apiService.createObligation(obligationData);
    return response.id;
  }

  Future<void> updateObligation(
    String obligationId,
    Map<String, dynamic> obligationData,
  ) async {
    await _apiService.updateObligation(obligationId, obligationData);
  }

  Future<void> deleteObligation(String obligationId) async {
    await _apiService.deleteObligation(obligationId);
  }

  Future<void> recordPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    await _apiService.recordObligationPayment(obligationId, paymentData);
  }
}
