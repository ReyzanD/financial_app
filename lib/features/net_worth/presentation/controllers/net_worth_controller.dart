import 'package:flutter/foundation.dart';
import 'package:financial_app/features/net_worth/data/repositories/net_worth_repository.dart';
import 'package:financial_app/services/logger_service.dart';

class NetWorthController extends ChangeNotifier {
  final NetWorthRepository _r;
  NetWorthController({required NetWorthRepository repository})
    : _r = repository;

  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic> _trend = {};
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get data => _data;
  List<Map<String, dynamic>> get history => _history;
  Map<String, dynamic> get trend => _trend;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _r.calculateNetWorth(),
        _r.getHistory(limit: 30),
        _r.getNetWorthTrend(),
      ]);
      _data = r[0] as Map<String, dynamic>;
      _history = r[1] as List<Map<String, dynamic>>;
      _trend = r[2] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('NetWorthController.loadData', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadData();

  Future<void> recordSnapshot() async {
    try {
      await _r.recordSnapshot();
      await refresh();
    } catch (e) {
      LoggerService.error('NetWorthController.recordSnapshot', error: e);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
