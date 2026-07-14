import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/account_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/models/account_model.dart';

class AccountService {
  final AccountDataService _accountData;
  final GoalDataService _goalData;

  AccountService({AccountDataService? accountData, GoalDataService? goalData})
    : _accountData = accountData ?? getIt<AccountDataService>(),
      _goalData = goalData ?? getIt<GoalDataService>();

  Future<List<AccountModel>> getAccounts({bool activeOnly = true}) async {
    return _accountData.getAccounts(activeOnly: activeOnly);
  }

  Future<AccountModel> createAccount(AccountModel account) async {
    return _accountData.addAccount(account.toMap());
  }

  Future<AccountModel> updateAccount(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return _accountData.updateAccount(id, updates);
  }

  Future<void> deleteAccount(String id) async {
    await _accountData.deleteAccount(id);
  }

  Future<void> adjustBalance(String id, double amount, {String? notes}) async {
    final accounts = await getAccounts(activeOnly: false);
    final index = accounts.indexWhere((a) => a.id == id);
    if (index == -1) throw Exception('Account not found');

    final existing = accounts[index];
    await updateAccount(id, {'balance': existing.balance + amount});
  }

  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? notes,
  }) async {
    final accounts = await getAccounts(activeOnly: false);
    final fromIndex = accounts.indexWhere((a) => a.id == fromAccountId);
    final toIndex = accounts.indexWhere((a) => a.id == toAccountId);

    if (fromIndex == -1 || toIndex == -1) {
      throw Exception('One or both accounts not found');
    }

    if (accounts[fromIndex].balance < amount) {
      throw Exception('Insufficient balance');
    }

    await updateAccount(fromAccountId, {
      'balance': accounts[fromIndex].balance - amount,
    });
    await updateAccount(toAccountId, {
      'balance': accounts[toIndex].balance + amount,
    });
  }

  Future<AccountModel?> getAccountById(String id) async {
    return _accountData.getAccount(id);
  }

  Future<Map<String, double>> getTotalBalanceByType() async {
    final accounts = await getAccounts();
    final totals = <String, double>{};

    for (var account in accounts) {
      totals[account.type] = (totals[account.type] ?? 0) + account.balance;
    }

    return totals;
  }

  Future<double> getTotalBalance() async {
    final accounts = await getAccounts();
    return accounts.fold<double>(0, (sum, account) => sum + account.balance);
  }

  Future<String> getDefaultAccountId() async {
    final accounts = await getAccounts(activeOnly: false);
    final defaultAccount = accounts.where((a) => a.isDefault).firstOrNull;
    return defaultAccount?.id ?? '';
  }

  Future<void> setDefaultAccountId(String id) async {
    await updateAccount(id, {'is_default': true});
  }

  Future<Map<String, dynamic>> getAccountSummary() async {
    return await _accountData.getAccountSummary();
  }

  /// Calculate available balance (total balance minus goal allocations)
  Future<double> getAvailableBalance() async {
    final totalBalance = await getTotalBalance();
    final totalGoals = await _goalData.getTotalGoalContributions();
    final available = totalBalance - totalGoals;
    return available < 0 ? 0 : available;
  }

  /// Get contributions for a goal
  Future<List<Map<String, dynamic>>> getGoalContributions(String goalId) async {
    return await _goalData.getGoalContributions(goalId);
  }
}
