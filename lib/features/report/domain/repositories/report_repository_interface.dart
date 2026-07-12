abstract class ReportRepositoryInterface {
  Future<Map<String, dynamic>> generateReport({
    required DateTime start,
    required DateTime end,
    String type = 'summary',
  });
}
