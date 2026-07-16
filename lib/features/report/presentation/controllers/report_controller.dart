import 'package:flutter/foundation.dart';
import 'package:financial_app/features/report/data/repositories/report_repository.dart';
import 'package:financial_app/services/logger_service.dart';

class ReportController extends ChangeNotifier {
  final ReportRepository _r;
  ReportController({required ReportRepository repository}) : _r = repository;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _reportData = {};
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get reportData => _reportData;

  Future<void> generate({required DateTime start, required DateTime end, String type = 'summary'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reportData = await _r.generateReport(start: start, end: end, type: type);
    } catch (e) {
      LoggerService.error('Error generating report', error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
