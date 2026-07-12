import 'package:flutter/foundation.dart';
import 'package:financial_app/features/cash_flow/domain/repositories/cash_flow_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class CashFlowController extends ChangeNotifier {
  final CashFlowRepositoryInterface _r;
  CashFlowController({required CashFlowRepositoryInterface repository})
    : _r = repository;

  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _weeklyForecast = {};
  List<Map<String, dynamic>> _dailyForecast = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get summary => _summary;
  Map<String, dynamic> get weeklyForecast => _weeklyForecast;
  List<Map<String, dynamic>> get dailyForecast => _dailyForecast;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final r = await Future.wait([
        _r.getCashFlowSummary(),
        _r.getWeeklyCashFlowForecast(weeks: 4),
        _r.forecastDailyCashFlow(days: 14),
      ]);
      _summary =
          r[0] is Map<String, dynamic> ? r[0] as Map<String, dynamic> : {};
      _weeklyForecast =
          r[1] is Map<String, dynamic> ? r[1] as Map<String, dynamic> : {};
      _dailyForecast =
          r[2] is List ? (r[2] as List).cast<Map<String, dynamic>>() : [];
    } catch (e) {
      LoggerService.error('CashFlowController.loadData', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadData();
}
