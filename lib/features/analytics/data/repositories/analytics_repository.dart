import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';

class AnalyticsRepository {
  final TransactionDataService _transactionData;
  AnalyticsRepository({TransactionDataService? transactionData})
    : _transactionData = transactionData ?? getIt<TransactionDataService>();

  Future<Map<String, dynamic>> getTransactions({int limit = 100, DateTime? startDate, DateTime? endDate}) =>
      _transactionData.getTransactions(
        limit: limit,
        startDate: startDate?.toIso8601String().split('T')[0],
        endDate: endDate?.toIso8601String().split('T')[0],
      );

  Future<Map<String, dynamic>> getFinancialSummary({required int year, required int month}) =>
      _transactionData.getFinancialSummary(year: year, month: month);
}
