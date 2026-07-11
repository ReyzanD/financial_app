import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/debt_data_service.dart';
import 'package:financial_app/models/debt_model.dart';

class DebtService {
  final DebtDataService _debtData;

  DebtService({DebtDataService? debtData})
    : _debtData = debtData ?? DebtDataService();

  Future<List<DebtModel>> getDebts({bool activeOnly = true}) async {
    try {
      final debtsData = await _debtData.getDebts(activeOnly: activeOnly);
      return debtsData.map((d) => DebtModel.fromMap(d)).toList();
    } catch (e) {
      LoggerService.error('Error getting debts', error: e);
      rethrow;
    }
  }

  Future<DebtModel> addDebt(DebtModel debt) async {
    try {
      final result = await _debtData.addDebt(debt.toMap());
      final created = DebtModel.fromMap(result['debt'] as Map<String, dynamic>);
      LoggerService.success('Debt added: ${created.name}');
      return created;
    } catch (e) {
      LoggerService.error('Error adding debt', error: e);
      rethrow;
    }
  }

  Future<void> recordPayment(
    String debtId,
    double amount, {
    String? notes,
  }) async {
    try {
      await _debtData.recordDebtPayment(debtId, amount, notes: notes);
      LoggerService.success('Payment recorded: $amount for debt $debtId');
    } catch (e) {
      LoggerService.error('Error recording payment', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String debtId) async {
    try {
      return await _debtData.getDebtPayments(debtId);
    } catch (e) {
      LoggerService.error('Error getting payment history', error: e);
      rethrow;
    }
  }

  Future<double> getTotalDebt() async {
    try {
      final summary = await _debtData.getDebtSummary();
      return (summary['total_debt'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      LoggerService.error('Error getting total debt', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDebtSummary() async {
    try {
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
    } catch (e) {
      LoggerService.error('Error getting debt summary', error: e);
      rethrow;
    }
  }

  Future<void> deleteDebt(String debtId) async {
    try {
      await _debtData.deleteDebt(debtId);
      LoggerService.success('Debt deleted');
    } catch (e) {
      LoggerService.error('Error deleting debt', error: e);
      rethrow;
    }
  }
}
