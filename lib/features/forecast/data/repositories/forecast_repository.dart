import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/features/forecast/domain/repositories/forecast_repository_interface.dart';

class ForecastRepository implements ForecastRepositoryInterface {
  final ApiService _api;
  ForecastRepository({ApiService? api}) : _api = api ?? getIt<ApiService>();

  @override
  Future<Map<String, dynamic>> getTransactions({int limit = 1000}) =>
      _api.getTransactions(limit: limit);
}
