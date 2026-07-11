abstract class ForecastRepositoryInterface {
  Future<Map<String, dynamic>> getTransactions({int limit = 1000});
}
