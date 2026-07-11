abstract class NetWorthRepositoryInterface {
  Future<Map<String, dynamic>> calculateNetWorth();
  Future<bool> recordSnapshot();
  Future<List<Map<String, dynamic>>> getHistory({int limit = 30});
  Future<Map<String, dynamic>> getNetWorthTrend();
}
