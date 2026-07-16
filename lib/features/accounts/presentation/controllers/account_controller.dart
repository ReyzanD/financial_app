import 'package:flutter/foundation.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/features/accounts/data/repositories/account_repository.dart';
import 'package:financial_app/services/logger_service.dart';

/// Controller for the Accounts feature.
class AccountController extends ChangeNotifier {
  final AccountRepository _repository;

  AccountController({required AccountRepository repository}) : _repository = repository;

  List<AccountModel> _accounts = [];
  double _totalBalance = 0.0;
  Map<String, double> _balanceByType = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _activeOnly = true;

  List<AccountModel> get accounts => _accounts;
  double get totalBalance => _totalBalance;
  Map<String, double> get balanceByType => _balanceByType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get activeOnly => _activeOnly;

  /// Load accounts, total balance, and breakdown by type.
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getAccounts(activeOnly: _activeOnly),
        _repository.getTotalBalance(),
        _repository.getTotalBalanceByType(),
      ]);

      _accounts = results[0] as List<AccountModel>;
      _totalBalance = results[1] as double;
      _balanceByType = results[2] as Map<String, double>;
    } catch (e) {
      LoggerService.error('AccountController.loadData', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh data (for RefreshIndicator).
  Future<void> refresh() async {
    await loadData();
  }

  /// Toggle active-only filter and reload.
  void toggleActiveOnly() {
    _activeOnly = !_activeOnly;
    loadData();
  }

  /// Delete an account and refresh.
  Future<void> deleteAccount(String id) async {
    try {
      await _repository.deleteAccount(id);
      await refresh();
    } catch (e) {
      LoggerService.error('AccountController.deleteAccount', error: e);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
