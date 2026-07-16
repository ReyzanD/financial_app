import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';

class ObligationService {
  final ObligationDataService _obligationData;
  ObligationService({ObligationDataService? obligationData})
    : _obligationData = obligationData ?? getIt<ObligationDataService>();

  Future<Map<String, dynamic>> getObligationsSummary() async {
    try {
      final obligations = await _obligationData.getObligations();
      double totalMonthly = 0.0;
      double totalDebt = 0.0;
      for (final o in obligations) {
        totalMonthly += o.monthlyAmount;
        totalDebt += o.currentBalance ?? o.monthlyAmount;
      }
      return {'monthlyTotal': totalMonthly, 'totalDebt': totalDebt, 'obligationsCount': obligations.length};
    } catch (e) {
      return {'monthlyTotal': 0.0, 'totalDebt': 0.0, 'obligationsCount': 0};
    }
  }

  Future<List<FinancialObligation>> getUpcomingObligations({int days = 7}) async {
    try {
      return await _obligationData.getUpcomingObligations(days: days);
    } catch (e) {
      return [];
    }
  }

  Future<List<FinancialObligation>> getObligations({String? type}) async {
    try {
      return await _obligationData.getObligations(type: type);
    } catch (e) {
      return [];
    }
  }

  Future<DebtSummary> getDebtSummary() async {
    try {
      final debts = await _obligationData.getObligations(type: 'debt');

      double totalDebt = 0.0;
      double monthlyPayments = 0.0;

      for (var debt in debts) {
        totalDebt += debt.currentBalance ?? 0.0;
        monthlyPayments += debt.monthlyAmount;
      }

      return DebtSummary(debts: debts, totalDebt: totalDebt, monthlyPayments: monthlyPayments);
    } catch (e) {
      return DebtSummary(debts: [], totalDebt: 0.0, monthlyPayments: 0.0);
    }
  }

  Future<List<FinancialObligation>> getSubscriptions() async {
    try {
      return await _obligationData.getObligations(type: 'subscription');
    } catch (e) {
      return [];
    }
  }

  Future<String> createObligation(Map<String, dynamic> obligationData) async {
    final response = await _obligationData.addObligation(obligationData);
    return response.id;
  }

  Future<void> updateObligation(String obligationId, Map<String, dynamic> obligationData) async {
    await _obligationData.updateObligation(obligationId, obligationData);
  }

  Future<void> deleteObligation(String obligationId) async {
    await _obligationData.deleteObligation(obligationId);
  }

  Future<void> recordPayment(String obligationId, Map<String, dynamic> paymentData) async {
    await _obligationData.recordObligationPayment(obligationId, paymentData);
  }
}
