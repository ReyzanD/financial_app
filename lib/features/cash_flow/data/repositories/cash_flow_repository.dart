import 'package:financial_app/services/cash_flow_forecast_service.dart';

class CashFlowRepository {
  final CashFlowForecastService _s;
  CashFlowRepository({required CashFlowForecastService service}) : _s = service;

  Future<Map<String, dynamic>> getCashFlowSummary() => _s.getCashFlowSummary();
  Future<Map<String, dynamic>> getWeeklyCashFlowForecast({int weeks = 4}) => _s.getWeeklyCashFlowForecast(weeks: weeks);
  Future<List<Map<String, dynamic>>> forecastDailyCashFlow({int days = 14}) => _s.forecastDailyCashFlow(days: days);
}
