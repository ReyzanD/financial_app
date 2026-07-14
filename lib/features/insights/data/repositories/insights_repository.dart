import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';

class InsightsRepository {
  final ApiService _api;
  InsightsRepository({ApiService? api}) : _api = api ?? getIt<ApiService>();

  Future<Map<String, dynamic>> getTransactions({int limit = 500}) =>
      _api.getTransactions(limit: limit);

  Future<List<dynamic>> getGoals() => _api.getGoals();
}
