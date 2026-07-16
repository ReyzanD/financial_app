import 'package:flutter/foundation.dart';
import 'package:financial_app/models/split_model.dart';
import 'package:financial_app/features/splits/data/repositories/split_repository.dart';
import 'package:financial_app/services/logger_service.dart';

class SplitController extends ChangeNotifier {
  final SplitRepository _r;
  SplitController({required SplitRepository repository}) : _r = repository;

  List<SplitModel> _splits = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _activeOnly = true;

  List<SplitModel> get splits => _splits;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get activeOnly => _activeOnly;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final r = await Future.wait([_r.getSplits(activeOnly: _activeOnly), _r.getSplitSummary()]);
      _splits = r[0] as List<SplitModel>;
      _summary = r[1] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('SplitController.loadData', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async => loadData();
  void toggleActiveOnly() {
    _activeOnly = !_activeOnly;
    loadData();
  }

  Future<void> deleteSplit(String id) async {
    try {
      await _r.deleteSplit(id);
      await refresh();
    } catch (e) {
      LoggerService.error('SplitController.delete', error: e);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
