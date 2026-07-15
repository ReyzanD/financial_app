import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';

/// Transaction Remote Data Source (Data Layer) - Now uses local database
class TransactionRemoteDataSource {
  final TransactionDataService _transactionData;
  TransactionRemoteDataSource({TransactionDataService? transactionData})
    : _transactionData = transactionData ?? getIt<TransactionDataService>();

  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    int? limit,
    int? offset,
  }) async {
    final result = await _transactionData.getTransactions(
      type: type,
      categoryId: categoryId,
      startDate: startDate?.toIso8601String().split('T')[0],
      endDate: endDate?.toIso8601String().split('T')[0],
      limit: limit ?? 100,
      offset: offset ?? 0,
    );
    final transactions = result['transactions'] as List;
    return transactions.map((t) => t as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> data,
  ) async {
    final model = await _transactionData.addTransaction(data);
    return model.toJson();
  }

  Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    final model = await _transactionData.updateTransaction(id, data);
    return model?.toJson() ?? <String, dynamic>{};
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionData.deleteTransaction(id);
  }
}
