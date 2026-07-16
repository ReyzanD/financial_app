import 'package:financial_app/services/data/account_data_service.dart';
import 'package:financial_app/services/data/transaction_template_data_service.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/models/transaction_template_model.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/data/expense_split_data_service.dart';
import 'package:financial_app/models/goal_model.dart';
import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/models/split_model.dart';
import 'package:financial_app/services/data/investment_data_service.dart';
import 'package:financial_app/models/challenge_model.dart';
import 'package:financial_app/services/data/challenge_data_service.dart';
import 'package:financial_app/models/category_model.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';

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
  Future<List<AccountModel>> getAccounts({bool activeOnly = true}) async =>
      _accounts.values.map((m) => AccountModel.fromMap(m)).toList();

  @override
  Future<AccountModel> addAccount(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['account_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _accounts[id] = record;
    return AccountModel.fromMap(record);
  }

  @override
  Future<AccountModel> updateAccount(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_accounts.containsKey(id)) {
      _accounts[id]!.addAll(_toDbFormat(data));
      return AccountModel.fromMap(_accounts[id]!);
    }
    throw Exception('Account not found');
  }

  @override
  Future<bool> deleteAccount(String id) async {
    _accounts.remove(id);
    return true;
  }

  @override
  Future<AccountModel?> getAccount(String accountId) async {
    final record =
        _accounts.values
            .where((a) => a['account_id_232143'] == accountId)
            .firstOrNull;
    return record != null ? AccountModel.fromMap(record) : null;
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
  Future<List<GoalModel>> getGoals() async =>
      _goals.values.map((g) => GoalModel.fromMap(g)).toList();

  @override
  Future<GoalModel> addGoal(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        Map<String, dynamic>.from(data)
          ..['goal_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _goals[id] = record;
    return GoalModel.fromMap(record);
  }

  @override
  Future<GoalModel> updateGoal(String id, Map<String, dynamic> data) async {
    if (_goals.containsKey(id)) {
      _goals[id]!.addAll(data);
    }
    return GoalModel.fromMap(_goals[id] ?? {});
  }

  @override
  Future<bool> deleteGoal(String id) async {
    _goals.remove(id);
    return true;
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

/// Fake [ExpenseSplitDataService] that stores data in-memory.
class FakeExpenseSplitDataService extends ExpenseSplitDataService {
  final Map<String, Map<String, dynamic>> _splits = {};
  int _counter = 0;
  String _nextId() => 'split_${++_counter}';

  @override
  Future<List<SplitModel>> getSplits({
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
    return result.map((m) => SplitModel.fromMap(m)).toList();
  }

  @override
  Future<SplitModel> addSplit(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['split_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _splits[id] = record;
    return SplitModel.fromMap(record);
  }

  @override
  Future<void> settleSplit(String splitId) async {
    if (_splits.containsKey(splitId)) {
      _splits[splitId]!['is_settled_232143'] = 1;
      _splits[splitId]!['settled_at_232143'] = DateTime.now().toIso8601String();
    }
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
  Future<bool> deleteSplit(String splitId) async {
    return _splits.remove(splitId) != null;
  }
}

/// Fake [InvestmentDataService] that stores data in-memory.
class FakeInvestmentDataService extends InvestmentDataService {
  final Map<String, Map<String, dynamic>> _investments = {};
  int _counter = 0;
  String _nextId() => 'inv_${++_counter}';

  @override
  Future<List<InvestmentModel>> getInvestments({String? type}) async {
    var result = _investments.values.toList();
    if (type != null) {
      result = result.where((i) => i['type_232143'] == type).toList();
    }
    return result.map((m) => InvestmentModel.fromMap(m)).toList();
  }

  @override
  Future<InvestmentModel> addInvestment(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['investment_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _investments[id] = record;
    return InvestmentModel.fromMap(record);
  }

  @override
  Future<void> updateInvestmentPrice(String invId, double newPrice) async {
    if (_investments.containsKey(invId)) {
      _investments[invId]!['current_price_232143'] = newPrice;
      _investments[invId]!['updated_at_232143'] =
          DateTime.now().toIso8601String();
    }
  }

  @override
  Future<bool> deleteInvestment(String invId) async {
    _investments.remove(invId);
    return true;
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
  Future<List<CategoryModel>> getCategories() async =>
      _categories.values.map((m) => CategoryModel.fromMap(m)).toList();

  @override
  Future<CategoryModel> addCategory(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['category_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1'
          ..['is_system_default_232143'] = 0;
    _categories[id] = record;
    return CategoryModel.fromMap(record);
  }

  @override
  Future<CategoryModel> updateCategory(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_categories.containsKey(id)) {
      _categories[id]!.addAll(_toDbFormat(data));
    }
    return CategoryModel.fromMap(_categories[id] ?? {});
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.remove(id);
  }
}

/// Fake [TransactionTemplateDataService] that stores data in-memory.
class FakeTransactionTemplateDataService
    extends TransactionTemplateDataService {
  final Map<String, TransactionTemplateModel> _templates = {};
  int _counter = 0;
  String _nextId() => 'tpl_${++_counter}';

  @override
  Future<List<TransactionTemplateModel>> getTransactionTemplates() async =>
      _templates.values.toList();

  @override
  Future<TransactionTemplateModel> addTransactionTemplate(
    Map<String, dynamic> templateData,
  ) async {
    final id = _nextId();
    final now = DateTime.now();
    final record = TransactionTemplateModel(
      id: id,
      name: templateData['name']?.toString() ?? '',
      amount: (templateData['amount'] as num?)?.toDouble() ?? 0.0,
      type: templateData['type']?.toString() ?? 'expense',
      categoryId: templateData['category_id']?.toString(),
      description: templateData['description']?.toString(),
      lastUsed: now,
      createdAt: now,
    );
    _templates[id] = record;
    return record;
  }

  @override
  Future<bool> deleteTransactionTemplate(String templateId) async {
    return _templates.remove(templateId) != null;
  }
}

/// Fake [ChallengeDataService] that stores data in-memory.
class FakeChallengeDataService extends ChallengeDataService {
  final Map<String, Map<String, dynamic>> _challenges = {};
  int _counter = 0;
  String _nextId() => 'challenge_${++_counter}';

  @override
  Future<List<ChallengeModel>> getChallenges({bool activeOnly = true}) async =>
      _challenges.values.map((m) => ChallengeModel.fromMap(m)).toList();

  @override
  Future<ChallengeModel> addChallenge(Map<String, dynamic> data) async {
    final id = _nextId();
    final record =
        _toDbFormat(data)
          ..['challenge_id_232143'] = id
          ..['user_id_232143'] = 'test_user_1';
    _challenges[id] = record;
    return ChallengeModel.fromMap(record);
  }

  @override
  Future<void> updateChallenge(String id, Map<String, dynamic> data) async {
    if (_challenges.containsKey(id)) {
      _challenges[id]!.addAll(_toDbFormat(data));
    }
  }

  @override
  Future<bool> deleteChallenge(String challengeId) async {
    return _challenges.remove(challengeId) != null;
  }
}

/// Fake [ObligationDataService] that stores all data in-memory.
class FakeObligationDataService extends ObligationDataService {
  final Map<String, FinancialObligation> _obligations = {};
  int _counter = 0;
  String _nextId() => 'obl_${++_counter}';

  @override
  Future<List<FinancialObligation>> getObligations({String? type}) async {
    var result = _obligations.values.toList();
    if (type != null) {
      result = result.where((o) => o.type.name == type).toList();
    }
    return result;
  }

  @override
  Future<List<FinancialObligation>> getUpcomingObligations({
    int days = 7,
  }) async {
    final cutoff = DateTime.now().add(Duration(days: days));
    return _obligations.values
        .where((o) => o.dueDate.isBefore(cutoff))
        .toList();
  }

  @override
  Future<FinancialObligation> addObligation(
    Map<String, dynamic> obligationData,
  ) async {
    final id = _nextId();
    final now = DateTime.now();

    // Build a map compatible with FinancialObligation.fromMap
    final record = <String, dynamic>{
      'obligation_id_232143': id,
      'user_id_232143': 'test_user_1',
      'name_232143': obligationData['name'] ?? '',
      'monthly_amount_232143':
          obligationData['amount'] ?? obligationData['monthly_amount'] ?? 0.0,
      'due_date_232143':
          obligationData['due_date']?.toString() ??
          obligationData['dueDate']?.toString() ??
          now.day.toString(),
      'type_232143': obligationData['type'] ?? 'bill',
      'category_232143': obligationData['category'],
      'original_amount_232143': obligationData['original_amount'],
      'current_balance_232143': obligationData['current_balance'],
      'interest_rate_232143': obligationData['interest_rate'],
      'is_subscription_232143':
          obligationData['is_subscription'] == true ? 1 : 0,
      'subscription_cycle_232143': obligationData['subscription_cycle'],
      'minimum_payment_232143': obligationData['minimum_payment'],
      'payoff_strategy_232143': obligationData['payoff_strategy'],
      'days_until_due': 0,
    };

    final obligation = FinancialObligation.fromMap(record);
    _obligations[id] = obligation;
    return obligation;
  }

  @override
  Future<FinancialObligation> updateObligation(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (!_obligations.containsKey(id)) {
      throw Exception('Obligation not found');
    }
    final existing = _obligations[id]!;
    final updated = FinancialObligation(
      id: existing.id,
      name: data['name']?.toString() ?? existing.name,
      monthlyAmount:
          (data['amount'] as num?)?.toDouble() ??
          (data['monthly_amount'] as num?)?.toDouble() ??
          existing.monthlyAmount,
      dueDate:
          data['due_date'] != null
              ? DateTime.parse(data['due_date'].toString())
              : data['dueDate'] != null
              ? DateTime.parse(data['dueDate'].toString())
              : existing.dueDate,
      type:
          data['type'] != null
              ? ObligationType.values.firstWhere(
                (e) => e.name == data['type'].toString(),
                orElse: () => ObligationType.bill,
              )
              : existing.type,
      category: data['category']?.toString() ?? existing.category,
      originalAmount:
          (data['original_amount'] as num?)?.toDouble() ??
          existing.originalAmount,
      currentBalance:
          (data['current_balance'] as num?)?.toDouble() ??
          existing.currentBalance,
      interestRate:
          (data['interest_rate'] as num?)?.toDouble() ?? existing.interestRate,
      isSubscription:
          data['is_subscription'] == true || existing.isSubscription,
      subscriptionCycle:
          data['subscription_cycle']?.toString() ?? existing.subscriptionCycle,
      minimumPayment:
          (data['minimum_payment'] as num?)?.toDouble() ??
          existing.minimumPayment,
      payoffStrategy:
          data['payoff_strategy']?.toString() ?? existing.payoffStrategy,
      daysUntilDue: existing.daysUntilDue,
    );
    _obligations[id] = updated;
    return updated;
  }

  @override
  Future<bool> deleteObligation(String id) async {
    return _obligations.remove(id) != null;
  }

  @override
  Future<Map<String, dynamic>> recordObligationPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    return {'success': true};
  }

  @override
  Map<String, dynamic> calculateObligationsSummary(
    List<FinancialObligation> obligations,
  ) {
    double totalMonthly = 0.0;
    for (var o in obligations) {
      totalMonthly += o.monthlyAmount;
    }
    return {
      'total_monthly': totalMonthly,
      'total_debt': totalMonthly,
      'active_count': obligations.length,
      'overdue_count': 0,
      'total_count': obligations.length,
    };
  }
}
