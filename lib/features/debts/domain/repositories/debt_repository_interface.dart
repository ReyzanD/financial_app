import 'package:financial_app/models/debt_model.dart';

abstract class DebtRepositoryInterface {
  Future<List<DebtModel>> getDebts({bool activeOnly = true});
  Future<DebtModel> addDebt(DebtModel debt);
  Future<void> deleteDebt(String id);
  Future<void> recordPayment(String debtId, double amount, {String? notes});
  Future<Map<String, dynamic>> getDebtSummary();
}
