import 'package:flutter/foundation.dart';
import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/features/debts/domain/repositories/debt_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class DebtController extends ChangeNotifier {
  final DebtRepositoryInterface _repository;

  DebtController({required DebtRepositoryInterface repository})
    : _repository = repository;

  List<DebtModel> _debts = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _activeOnly = true;

  List<DebtModel> get debts => _debts;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get activeOnly => _activeOnly;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getDebts(activeOnly: _activeOnly),
        _repository.getDebtSummary(),
      ]);
      _debts = results[0] as List<DebtModel>;
      _summary = results[1] as Map<String, dynamic>;
    } catch (e) {
      LoggerService.error('DebtController.loadData', error: e);
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

  Future<void> deleteDebt(String id) async {
    try {
      await _repository.deleteDebt(id);
      await refresh();
    } catch (e) {
      LoggerService.error('DebtController.deleteDebt', error: e);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
