abstract class AnalyticsRepositoryInterface {
  Future<Map<String, dynamic>> getTransactions({
    int limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Map<String, dynamic>> getFinancialSummary({
    required int year,
    required int month,
  });
}
