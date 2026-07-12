import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/features/recurring_transactions/domain/repositories/recurring_transaction_repository_interface.dart';

class RecurringTransactionRepository
    implements RecurringTransactionRepositoryInterface {
  final ApiService _api;
  RecurringTransactionRepository({ApiService? api})
    : _api = api ?? getIt<ApiService>();

  @override
  Future<List<Map<String, dynamic>>> getRecurringTransactions({
    bool activeOnly = true,
  }) async {
    final data = await _api.getRecurringTransactions(activeOnly: activeOnly);
    return data
        .whereType<Map<String, dynamic>>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  @override
  Future<void> pauseRecurringTransaction(String id) =>
      _api.pauseRecurringTransaction(id);
  @override
  Future<void> resumeRecurringTransaction(String id) =>
      _api.resumeRecurringTransaction(id);
  @override
  Future<void> deleteRecurringTransaction(String id) =>
      _api.deleteRecurringTransaction(id);
}
