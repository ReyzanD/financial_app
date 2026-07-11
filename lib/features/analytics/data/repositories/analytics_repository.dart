import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/features/analytics/domain/repositories/analytics_repository_interface.dart';

class AnalyticsRepository implements AnalyticsRepositoryInterface {
  final ApiService _api;
  AnalyticsRepository({ApiService? api}) : _api = api ?? getIt<ApiService>();

  @override
  Future<Map<String, dynamic>> getTransactions({int limit = 100, DateTime? startDate, DateTime? endDate}) =>
      _api.getTransactions(limit: limit, startDate: startDate, endDate: endDate);

  @override
  Future<Map<String, dynamic>> getFinancialSummary({required int year, required int month}) =>
      _api.getFinancialSummary(year: year, month: month);
}
