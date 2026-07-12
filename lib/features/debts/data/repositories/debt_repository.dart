import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/services/debt_service.dart';
import 'package:financial_app/features/debts/domain/repositories/debt_repository_interface.dart';

class DebtRepository implements DebtRepositoryInterface {
  final DebtService _debtService;
  DebtRepository({DebtService? debtService})
    : _debtService = debtService ?? DebtService();

  @override
  Future<List<DebtModel>> getDebts({bool activeOnly = true}) async =>
      _debtService.getDebts(activeOnly: activeOnly);

  @override
  Future<DebtModel> addDebt(DebtModel debt) async => _debtService.addDebt(debt);

  @override
  Future<void> deleteDebt(String id) async => _debtService.deleteDebt(id);

  @override
  Future<void> recordPayment(
    String debtId,
    double amount, {
    String? notes,
  }) async => _debtService.recordPayment(debtId, amount, notes: notes);

  @override
  Future<Map<String, dynamic>> getDebtSummary() async =>
      _debtService.getDebtSummary();
}
