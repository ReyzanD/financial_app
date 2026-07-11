import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/features/insights/domain/repositories/insights_repository_interface.dart';

class InsightsRepository implements InsightsRepositoryInterface {
  final ApiService _api;
  InsightsRepository({ApiService? api}) : _api = api ?? getIt<ApiService>();

  @override
  Future<Map<String, dynamic>> getTransactions({int limit = 500}) => _api.getTransactions(limit: limit);

  @override
  Future<List<dynamic>> getGoals() => _api.getGoals();
}
