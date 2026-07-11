abstract class InsightsRepositoryInterface {
  Future<Map<String, dynamic>> getTransactions({int limit = 500});
  Future<List<dynamic>> getGoals();
}
