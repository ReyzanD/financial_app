import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';

class ForecastRepository {
  final TransactionDataService _transactionData;
  ForecastRepository({TransactionDataService? transactionData})
      : _transactionData = transactionData ?? getIt<TransactionDataService>();

  Future<Map<String, dynamic>> getTransactions({int limit = 1000}) =>
      _transactionData.getTransactions(limit: limit);
}
