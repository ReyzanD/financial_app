import 'package:financial_app/services/net_worth_service.dart';
import 'package:financial_app/features/net_worth/domain/repositories/net_worth_repository_interface.dart';

class NetWorthRepository implements NetWorthRepositoryInterface {
  final NetWorthService _s;
  NetWorthRepository({NetWorthService? service}) : _s = service ?? NetWorthService();

  @override Future<Map<String, dynamic>> calculateNetWorth() => _s.calculateNetWorth();
  @override Future<bool> recordSnapshot() => _s.recordSnapshot();
  @override Future<List<Map<String, dynamic>>> getHistory({int limit = 30}) => _s.getHistory(limit: limit);
  @override Future<Map<String, dynamic>> getNetWorthTrend() => _s.getNetWorthTrend();
}
