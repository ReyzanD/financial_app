import 'package:financial_app/services/net_worth_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class NetWorthRepository {
  final NetWorthService _s;
  NetWorthRepository({NetWorthService? service})
    : _s = service ?? getIt<NetWorthService>();

  Future<Map<String, dynamic>> calculateNetWorth() => _s.calculateNetWorth();
  Future<bool> recordSnapshot() => _s.recordSnapshot();
  Future<List<Map<String, dynamic>>> getHistory({int limit = 30}) =>
      _s.getHistory(limit: limit);
  Future<Map<String, dynamic>> getNetWorthTrend() => _s.getNetWorthTrend();
}
