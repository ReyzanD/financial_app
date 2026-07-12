import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';

/// Transaction Remote Data Source (Data Layer) - Now uses local database
class TransactionRemoteDataSource {
  final ApiService _apiService;
  TransactionRemoteDataSource({ApiService? apiService})
    : _apiService = apiService ?? getIt<ApiService>();

  Future<List<Map<String, dynamic>>> getTransactions({
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    int? limit,
    int? offset,
  }) async {
    final result = await _apiService.getTransactions(
      type: type,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      limit: limit ?? 100,
      offset: offset ?? 0,
    );
    final transactions = result['transactions'] as List;
    return transactions.map((t) => t as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> data,
  ) async {
    return await _apiService.addTransaction(data);
  }

  Future<Map<String, dynamic>> updateTransaction(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _apiService.updateTransaction(id, data);
  }

  Future<void> deleteTransaction(String id) async {
    await _apiService.deleteTransaction(id);
  }
}
