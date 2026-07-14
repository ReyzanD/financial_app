import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';

class ForecastRepository {
  final ApiService _api;
  ForecastRepository({ApiService? api}) : _api = api ?? getIt<ApiService>();

  Future<Map<String, dynamic>> getTransactions({int limit = 1000}) =>
      _api.getTransactions(limit: limit);
}
