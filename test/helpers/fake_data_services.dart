import 'package:financial_app/services/data/account_data_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/data/debt_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/data/subscription_data_service.dart';
import 'package:financial_app/services/data/expense_split_data_service.dart';
import 'package:financial_app/services/data/investment_data_service.dart';

/// Transforms clean JSON keys to `_232143` suffixed DB format.
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

/// Fake [AccountDataService] that stores data in-memory.
class FakeAccountDataService extends AccountDataService {
  final Map<String, Map<String, dynamic>> _accounts = {};
  int _counter = 0;
  String _nextId() => 'acc_${++_counter}';

  @override
  Future<List<Map<String, dynamic>>> getAccounts({
    bool activeOnly = true,
  }) async => _accounts.values.toList();

  @override
  Future<Map<String, dynamic>> addAccount(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['account_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _accounts[id] = record;
    return {'account': Map<String, dynamic>.from(record)};
  }

  @override
  Future<Map<String, dynamic>> updateAccount(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_accounts.containsKey(id)) {
      _accounts[id]!.addAll(_toDbFormat(data));
    }
    return {'account': Map<String, dynamic>.from(_accounts[id] ?? {})};
  }

  @override
  Future<Map<String, dynamic>> deleteAccount(String id) async {
    _accounts.remove(id);
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> getAccount(String accountId) async {
    final record =
        _accounts.values
            .where((a) => a['account_id_232143'] == accountId)
            .firstOrNull;
    return {
      'account': record != null ? Map<String, dynamic>.from(record) : null,
    };
  }

  @override
  Future<Map<String, dynamic>> getAccountSummary() async {
    double totalBalance = 0;
    for (var a in _accounts.values) {
      totalBalance += (a['balance_232143'] as num?)?.toDouble() ?? 0;
    }
    return {'total_accounts': _accounts.length, 'total_balance': totalBalance};
  }
}

/// Fake [GoalDataService] that stores data in-memory.
class FakeGoalDataService extends GoalDataService {
  final Map<String, Map<String, dynamic>> _goals = {};
  int _counter = 0;
  String _nextId() => 'goal_${++_counter}';

  @override
  Future<List<Map<String, dynamic>>> getGoals() async => _goals.values.toList();

  @override
  Future<Map<String, dynamic>> addGoal(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        Map<String, dynamic>.from(data)
          ..['goal_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _goals[id] = record;
    return {'goal': record};
  }

  @override
  Future<Map<String, dynamic>> updateGoal(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_goals.containsKey(id)) {
      _goals[id]!.addAll(data);
    }
    return {'goal': _goals[id] ?? {}};
  }

  @override
  Future<Map<String, dynamic>> deleteGoal(String id) async {
    _goals.remove(id);
    return {'success': true};
  }

  @override
  Future<double> getTotalGoalContributions() async {
    double total = 0;
    for (var g in _goals.values) {
      total += (g['current_amount_232143'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  @override
  Future<List<Map<String, dynamic>>> getGoalContributions(String goalId) async {
    return [];
  }
}

/// Fake [DebtDataService] that stores data in-memory.
class FakeDebtDataService extends DebtDataService {
  final Map<String, Map<String, dynamic>> _debts = {};
  int _counter = 0;
  String _nextId() => 'debt_${++_counter}';

  @override
  Future<List<Map<String, dynamic>>> getDebts({bool activeOnly = true}) async =>
      _debts.values.toList();

  @override
  Future<Map<String, dynamic>> addDebt(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['debt_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1'
          ..['current_balance_232143'] =
              (data['original_amount'] as num?)?.toDouble() ?? 0.0
          ..['paid_amount_232143'] = 0.0
          ..['created_at_232143'] = DateTime.now().toIso8601String()
          ..['updated_at_232143'] = DateTime.now().toIso8601String();
    _debts[id] = record;
    return {'debt': Map<String, dynamic>.from(record)};
  }

  @override
  Future<Map<String, dynamic>> recordDebtPayment(
    String debtId,
    double amount, {
    String? notes,
  }) async {
    if (_debts.containsKey(debtId)) {
      final currentPaid =
          (_debts[debtId]!['paid_amount_232143'] as num?)?.toDouble() ?? 0;
      _debts[debtId]!['paid_amount_232143'] = currentPaid + amount;
    }
    return {'success': true};
  }

  @override
  Future<List<Map<String, dynamic>>> getDebtPayments(String debtId) async => [];

  @override
  Future<Map<String, dynamic>> getDebtSummary() async {
    double totalDebt = 0;
    for (var d in _debts.values) {
      totalDebt += (d['current_balance_232143'] as num?)?.toDouble() ?? 0;
    }
    return {
      'total_debt': totalDebt,
      'total_paid': 0,
      'active_debts': _debts.length,
    };
  }

  @override
  Future<Map<String, dynamic>> deleteDebt(String debtId) async {
    _debts.remove(debtId);
    return {'success': true};
  }
}

/// Fake [SubscriptionDataService] that stores data in-memory.
class FakeSubscriptionDataService extends SubscriptionDataService {
  final Map<String, Map<String, dynamic>> _subscriptions = {};
  int _counter = 0;
  String _nextId() => 'sub_${++_counter}';

  @override
  Future<List<Map<String, dynamic>>> getSubscriptions({
    bool activeOnly = true,
  }) async => _subscriptions.values.toList();

  @override
  Future<Map<String, dynamic>> addSubscription(
    Map<String, dynamic> data,
  ) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['subscription_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _subscriptions[id] = record;
    return {'subscription': Map<String, dynamic>.from(record)};
  }

  @override
  Future<Map<String, dynamic>> updateSubscription(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_subscriptions.containsKey(id)) {
      _subscriptions[id]!.addAll(_toDbFormat(data));
    }
    return {
      'subscription': Map<String, dynamic>.from(_subscriptions[id] ?? {}),
    };
  }

  @override
  Future<Map<String, dynamic>> deleteSubscription(String id) async {
    _subscriptions.remove(id);
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> getSubscriptionSummary() async {
    double totalMonthly = 0;
    int activeCount = 0;
    for (var s in _subscriptions.values) {
      totalMonthly += (s['monthly_cost_232143'] as num?)?.toDouble() ?? 0;
      if ((s['is_active_232143'] as int? ?? 1) == 1) activeCount++;
    }
    return {
      'total_monthly': totalMonthly,
      'total_yearly': totalMonthly * 12,
      'active_count': activeCount,
    };
  }
}

/// Fake [ExpenseSplitDataService] that stores data in-memory.
class FakeExpenseSplitDataService extends ExpenseSplitDataService {
  final Map<String, Map<String, dynamic>> _splits = {};
  int _counter = 0;
  String _nextId() => 'split_${++_counter}';

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
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['split_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _splits[id] = record;
    return {'split': Map<String, dynamic>.from(record)};
  }

  @override
  Future<Map<String, dynamic>> settleSplit(String splitId) async {
    if (_splits.containsKey(splitId)) {
      _splits[splitId]!['is_settled_232143'] = 1;
      _splits[splitId]!['settled_at_232143'] = DateTime.now().toIso8601String();
    }
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> getSplitSummary() async {
    double totalOwed = 0;
    for (var s in _splits.values) {
      final amount = (s['amount_232143'] as num?)?.toDouble() ?? 0;
      final paid = (s['paid_amount_232143'] as num?)?.toDouble() ?? 0;
      totalOwed += amount - paid;
    }
    return {'total_owed': totalOwed, 'unsettled_count': _splits.length};
  }

  @override
  Future<Map<String, dynamic>> deleteSplit(String splitId) async {
    _splits.remove(splitId);
    return {'success': true};
  }
}

/// Fake [InvestmentDataService] that stores data in-memory.
class FakeInvestmentDataService extends InvestmentDataService {
  final Map<String, Map<String, dynamic>> _investments = {};
  int _counter = 0;
  String _nextId() => 'inv_${++_counter}';

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
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['investment_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _investments[id] = record;
    return {'investment': Map<String, dynamic>.from(record)};
  }

  @override
  Future<Map<String, dynamic>> updateInvestmentPrice(
    String invId,
    double newPrice,
  ) async {
    if (_investments.containsKey(invId)) {
      _investments[invId]!['current_price_232143'] = newPrice;
      _investments[invId]!['updated_at_232143'] =
          DateTime.now().toIso8601String();
    }
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> deleteInvestment(String invId) async {
    _investments.remove(invId);
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> getPortfolioSummary() async {
    double totalValue = 0;
    double totalCost = 0;
    for (var i in _investments.values) {
      totalValue += (i['current_value_232143'] as num?)?.toDouble() ?? 0;
      totalCost += (i['total_cost_232143'] as num?)?.toDouble() ?? 0;
    }
    return {
      'total_value': totalValue,
      'total_cost': totalCost,
      'total_profit_loss': totalValue - totalCost,
      'investments_count': _investments.length,
    };
  }
}

/// Fake [CategoryDataService] that stores data in-memory.
class FakeCategoryDataService extends CategoryDataService {
  final Map<String, Map<String, dynamic>> _categories = {};
  int _counter = 0;
  String _nextId() => 'cat_${++_counter}';

  @override
  Future<List<Map<String, dynamic>>> getCategories() async =>
      _categories.values.toList();

  @override
  Future<Map<String, dynamic>> addCategory(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['category_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1'
          ..['is_system_default_232143'] = 0;
    _categories[id] = record;
    return {'category': Map<String, dynamic>.from(record)};
  }

  @override
  Future<Map<String, dynamic>> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_categories.containsKey(id)) {
      _categories[id]!.addAll(_toDbFormat(data));
    }
    return {'category': Map<String, dynamic>.from(_categories[id] ?? {})};
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.remove(id);
  }
}
