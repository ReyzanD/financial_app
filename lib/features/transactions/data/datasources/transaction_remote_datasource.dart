import 'package:financial_app/services/api/transaction_api.dart';

/// Transaction Remote Data Source (Data Layer)
class TransactionRemoteDataSource {
  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    int limit = 100,
  }) async {
    final result = await TransactionApi.getTransactions(
      type: type,
      categoryId: categoryId,
      startDate: startDate?.toIso8601String(),
      endDate: endDate?.toIso8601String(),
      limit: limit,
    );
    return result.map((t) => t as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data) async {
    return await TransactionApi.addTransaction(data);
  }

  Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await TransactionApi.updateTransaction(id, data);
  }

  Future<void> deleteTransaction(String id) async {
    await TransactionApi.deleteTransaction(id);
  }
}

