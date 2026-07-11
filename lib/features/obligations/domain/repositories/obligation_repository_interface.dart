abstract class ObligationRepositoryInterface {
  Future<Map<String, dynamic>> getObligationsSummary();
  Future<List<dynamic>> getObligations();
}
