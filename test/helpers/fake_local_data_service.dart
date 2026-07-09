import 'package:sqflite/sqflite.dart';
import 'package:financial_app/services/local_data_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/local_database_service.dart';

/// A fake [LocalDataService] for unit tests that stores data in-memory
/// instead of using SQLite.
///
/// Simulates the real [LocalDataService] behavior where keys are transformed
/// to `_232143` suffixed format (matching the DB schema), and return values
/// are wrapped under entity keys like `{'debt': data}`.
class FakeLocalDataService extends LocalDataService {
  FakeLocalDataService()
    : super(
        // Use a minimal local auth service that returns a fixed user ID
        authService: _FakeAuthService(),
        // Minimal DB service — schema is irrelevant since we override
        // every method that touches the database.
        dbService: _FakeDatabaseService(),
      );

  // ==================== In-Memory Storage ====================
  final Map<String, Map<String, dynamic>> _accounts = {};
  final Map<String, Map<String, dynamic>> _categories = {};
  final Map<String, Map<String, dynamic>> _debts = {};
  final Map<String, Map<String, dynamic>> _debtPayments = {};
  final Map<String, Map<String, dynamic>> _subscriptions = {};
  final Map<String, Map<String, dynamic>> _splits = {};
  final Map<String, Map<String, dynamic>> _investments = {};

  int _counter = 0;
  String _nextId(String prefix) => '${prefix}_${++_counter}';

  /// Transforms clean JSON keys to `_232143` suffixed DB format.
  /// Simulates what the real [LocalDataService] does before storing.
  Map<String, dynamic> _toDbFormat(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (!key.endsWith('_232143')) {
        result['${key}_232143'] = value;
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  // ==================== ACCOUNTS ====================
  @override
  Future<List<Map<String, dynamic>>> getAccounts({
    bool activeOnly = true,
  }) async {
    return _accounts.values.toList();
  }

  @override
  Future<Map<String, dynamic>> addAccount(Map<String, dynamic> data) async {
    final id = _nextId('acc');
    final record =
        _toDbFormat(data)
          ..['account_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _accounts[id] = record;
    return {'account': record};
  }

  @override
  Future<Map<String, dynamic>> updateAccount(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_accounts.containsKey(id)) {
      _accounts[id]!.addAll(_toDbFormat(data));
    }
    return {'account': _accounts[id] ?? {}};
  }

  @override
  Future<Map<String, dynamic>> deleteAccount(String id) async {
    _accounts.remove(id);
    return {'account': {}};
  }

  @override
  Future<Map<String, dynamic>> getAccount(String id) async {
    return {'account': _accounts[id]};
  }

  @override
  Future<Map<String, dynamic>> getAccountSummary() async {
    return {'total_balance': 0.0, 'account_count': _accounts.length};
  }

  @override
  Future<double> getTotalGoalContributions() async => 0.0;

  @override
  Future<List<Map<String, dynamic>>> getGoalContributions(
    String goalId,
  ) async => [];

  // ==================== DEBTS ====================
  @override
  Future<List<Map<String, dynamic>>> getDebts({bool activeOnly = true}) async {
    return _debts.values.toList();
  }

  @override
  Future<Map<String, dynamic>> addDebt(Map<String, dynamic> data) async {
    final id = _nextId('debt');
    final record =
        _toDbFormat(data)
          ..['debt_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    // Simulate real behavior: current_balance defaults to original_amount
    if (!record.containsKey('current_balance_232143') ||
        record['current_balance_232143'] == null) {
      record['current_balance_232143'] = data['original_amount'] ?? 0.0;
    }
    _debts[id] = record;
    return {'debt': record};
  }

  @override
  Future<Map<String, dynamic>> recordDebtPayment(
    String debtId,
    double amount, {
    String? notes,
  }) async {
    _debtPayments['payment_${_debtPayments.length + 1}'] = {
      'debt_id_232143': debtId,
      'amount_232143': amount,
    };
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getDebtPayments(String debtId) async {
    return _debtPayments.values
        .where((p) => p['debt_id_232143'] == debtId)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getDebtSummary() async {
    return {
      'total_debt': 0.0,
      'total_monthly': 0.0,
      'debt_count': _debts.length,
    };
  }

  // ==================== SUBSCRIPTIONS ====================
  @override
  Future<List<Map<String, dynamic>>> getSubscriptions({
    bool activeOnly = true,
  }) async {
    return _subscriptions.values.toList();
  }

  @override
  Future<Map<String, dynamic>> addSubscription(
    Map<String, dynamic> data,
  ) async {
    final id = _nextId('sub');
    final record =
        _toDbFormat(data)
          ..['subscription_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _subscriptions[id] = record;
    return {'subscription': record};
  }

  @override
  Future<Map<String, dynamic>> updateSubscription(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_subscriptions.containsKey(id)) {
      _subscriptions[id]!.addAll(_toDbFormat(data));
    }
    return {'subscription': _subscriptions[id] ?? {}};
  }

  @override
  Future<Map<String, dynamic>> getSubscriptionSummary() async {
    return {
      'total_monthly': 0.0,
      'total_yearly': 0.0,
      'subscription_count': _subscriptions.length,
    };
  }

  // ==================== SPLITS ====================
  @override
  Future<List<Map<String, dynamic>>> getSplits({
    String? transactionId,
    bool activeOnly = true,
  }) async {
    var result = _splits.values.toList();
    if (transactionId != null) {
      result =
          result
              .where((s) => s['transaction_id_232143'] == transactionId)
              .toList();
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> addSplit(Map<String, dynamic> data) async {
    final id = _nextId('split');
    final record = _toDbFormat(data)..['split_id_232143'] = id;
    _splits[id] = record;
    return {'split': record};
  }

  @override
  Future<Map<String, dynamic>> settleSplit(String splitId) async {
    if (_splits.containsKey(splitId)) {
      _splits[splitId]!['is_settled_232143'] = 1;
    }
    return {'split': _splits[splitId] ?? {}};
  }

  @override
  Future<Map<String, dynamic>> getSplitSummary() async {
    return {'total_splits': _splits.length};
  }

  @override
  Future<Map<String, dynamic>> deleteSplit(String splitId) async {
    _splits.remove(splitId);
    return {};
  }

  // ==================== INVESTMENTS ====================
  @override
  Future<List<Map<String, dynamic>>> getInvestments({String? type}) async {
    var result = _investments.values.toList();
    if (type != null) {
      result = result.where((i) => i['type_232143'] == type).toList();
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> addInvestment(Map<String, dynamic> data) async {
    final id = _nextId('inv');
    final record =
        _toDbFormat(data)
          ..['investment_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _investments[id] = record;
    return {'investment': record};
  }

  @override
  Future<Map<String, dynamic>> updateInvestmentPrice(
    String invId,
    double newPrice,
  ) async {
    if (_investments.containsKey(invId)) {
      _investments[invId]!['current_price_232143'] = newPrice;
    }
    return {'investment': _investments[invId] ?? {}};
  }

  @override
  Future<Map<String, dynamic>> deleteInvestment(String invId) async {
    _investments.remove(invId);
    return {};
  }

  @override
  Future<Map<String, dynamic>> getPortfolioSummary() async {
    return {
      'total_value': 0.0,
      'total_cost': 0.0,
      'total_profit_loss': 0.0,
      'investment_count': _investments.length,
    };
  }

  // ==================== CATEGORIES ====================
  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    return _categories.values.toList();
  }

  @override
  Future<Map<String, dynamic>> addCategory(Map<String, dynamic> data) async {
    final id = _nextId('cat');
    final record =
        _toDbFormat(data)
          ..['category_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1'
          // Ensure id is accessible without suffix too (for convenience)
          ..['id'] = id;
    _categories[id] = record;
    return {'category': record};
  }

  @override
  Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_categories.containsKey(id)) {
      _categories[id]!.addAll(_toDbFormat(data));
    }
    return {'category': _categories[id] ?? {}};
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.remove(id);
  }
}

/// Fake auth service that always returns a fixed user ID.
class _FakeAuthService extends LocalAuthService {
  @override
  Future<String?> getCurrentUserId() async => 'test_user_1';
}

/// Fake database service that does nothing (all SQL operations are bypassed).
class _FakeDatabaseService extends LocalDatabaseService {
  _FakeDatabaseService() : super.test();

  /// Not used — all methods that touch the database are overridden in
  /// [FakeLocalDataService].
  @override
  Future<Database> get database async => null!;
}
