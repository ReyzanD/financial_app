import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class ReportRepository {
  final TransactionDataService _s;
  ReportRepository({TransactionDataService? service}) : _s = service ?? getIt<TransactionDataService>();
  Future<Map<String, dynamic>> generateReport({
    required DateTime start,
    required DateTime end,
    String type = 'summary',
  }) => _s.getTransactions(
    startDate: start.toIso8601String().split('T')[0],
    endDate: end.toIso8601String().split('T')[0],
  );
}
