import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/debt_data_service.dart';
import 'package:financial_app/models/debt_model.dart';

class DebtService {
  final DebtDataService _debtData;

  DebtService({DebtDataService? debtData})
      : _debtData = debtData ?? getIt<DebtDataService>();

  Future<List<DebtModel>> getDebts({bool activeOnly = true}) async {
    return _debtData.getDebts(activeOnly: activeOnly);
  }

  Future<DebtModel> addDebt(DebtModel debt) async {
    final created = await _debtData.addDebt(debt.toMap());
    return created;
  }

  Future<void> recordPayment(
    String debtId,
    double amount, {
    String? notes,
  }) async {
    await _debtData.recordDebtPayment(debtId, amount, notes: notes);
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String debtId) async {
    return _debtData.getDebtPayments(debtId);
  }

  Future<double> getTotalDebt() async {
    final summary = await _debtData.getDebtSummary();
    return (summary['total_debt'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>> getDebtSummary() async {
    final summary = await _debtData.getDebtSummary();
    final debts = await getDebts();
    final debtsByType = <String, double>{};

    for (var debt in debts) {
      debtsByType[debt.type] =
          (debtsByType[debt.type] ?? 0) + debt.currentBalance;
    }

    return {
      ...summary,
      'debts_by_type': debtsByType,
      'total_interest': debts.fold<double>(
        0,
        (sum, d) => sum + d.totalInterest,
      ),
    };
  }

  Future<void> deleteDebt(String debtId) async {
    await _debtData.deleteDebt(debtId);
  }
}
