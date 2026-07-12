import 'package:financial_app/services/cash_flow_forecast_service.dart';
import 'package:financial_app/features/cash_flow/domain/repositories/cash_flow_repository_interface.dart';

class CashFlowRepository implements CashFlowRepositoryInterface {
  final CashFlowForecastService _s;
  CashFlowRepository({required CashFlowForecastService service}) : _s = service;

  @override
  Future<Map<String, dynamic>> getCashFlowSummary() => _s.getCashFlowSummary();
  @override
  Future<Map<String, dynamic>> getWeeklyCashFlowForecast({int weeks = 4}) =>
      _s.getWeeklyCashFlowForecast(weeks: weeks);
  @override
  Future<List<Map<String, dynamic>>> forecastDailyCashFlow({int days = 14}) =>
      _s.forecastDailyCashFlow(days: days);
}
