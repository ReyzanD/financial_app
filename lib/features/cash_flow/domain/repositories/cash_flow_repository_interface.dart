abstract class CashFlowRepositoryInterface {
  Future<Map<String, dynamic>> getCashFlowSummary();
  Future<Map<String, dynamic>> getWeeklyCashFlowForecast({int weeks = 4});
  Future<List<Map<String, dynamic>>> forecastDailyCashFlow({int days = 14});
}
