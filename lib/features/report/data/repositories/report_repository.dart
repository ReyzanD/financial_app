import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/features/report/domain/repositories/report_repository_interface.dart';

class ReportRepository implements ReportRepositoryInterface {
  final TransactionDataService _s;
  ReportRepository({TransactionDataService? service}) : _s = service ?? TransactionDataService();
  @override Future<Map<String, dynamic>> generateReport({required DateTime start, required DateTime end, String type = 'summary'}) => _s.getTransactions(startDate: start.toIso8601String().split('T')[0], endDate: end.toIso8601String().split('T')[0]);
}
