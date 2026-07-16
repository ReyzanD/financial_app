import 'dart:async';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Map Repository - delegates to TransactionDataService, adds cross-cutting logic.
class MapRepository {
  final TransactionDataService _transactionData;

  MapRepository({TransactionDataService? transactionData})
      : _transactionData = transactionData ?? getIt<TransactionDataService>();

  Future<Map<String, dynamic>> getTransactions({int limit = 100}) async {
    return await _transactionData.getTransactions(limit: limit);
  }
}
