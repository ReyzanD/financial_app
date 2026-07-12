import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/account_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/models/account_model.dart';

class AccountService {
  final AccountDataService _accountData;
  final GoalDataService _goalData;

  AccountService({AccountDataService? accountData, GoalDataService? goalData})
    : _accountData = accountData ?? AccountDataService(),
      _goalData = goalData ?? GoalDataService();

  Future<List<AccountModel>> getAccounts({bool activeOnly = true}) async {
    try {
      final accountsData = await _accountData.getAccounts(
        activeOnly: activeOnly,
      );
      return accountsData.map((a) => AccountModel.fromMap(a)).toList();
    } catch (e) {
      LoggerService.error('Error getting accounts', error: e);
      rethrow;
    }
  }

  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final result = await _accountData.addAccount(account.toMap());
      final created = AccountModel.fromMap(
        result['account'] as Map<String, dynamic>,
      );
      LoggerService.success('Account created: ${created.name}');
      return created;
    } catch (e) {
      LoggerService.error('Error creating account', error: e);
      rethrow;
    }
  }

  Future<AccountModel> updateAccount(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final result = await _accountData.updateAccount(id, updates);
      final updated = AccountModel.fromMap(
        result['account'] as Map<String, dynamic>,
      );
      LoggerService.success('Account updated: ${updated.name}');
      return updated;
    } catch (e) {
      LoggerService.error('Error updating account', error: e);
      rethrow;
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _accountData.deleteAccount(id);
      LoggerService.success('Account deleted');
    } catch (e) {
      LoggerService.error('Error deleting account', error: e);
      rethrow;
    }
  }

  Future<void> adjustBalance(String id, double amount, {String? notes}) async {
    try {
      final accounts = await getAccounts(activeOnly: false);
      final index = accounts.indexWhere((a) => a.id == id);
      if (index == -1) throw Exception('Account not found');

      final existing = accounts[index];
      await updateAccount(id, {'balance': existing.balance + amount});
      LoggerService.success('Balance adjusted: $amount for ${existing.name}');
    } catch (e) {
      LoggerService.error('Error adjusting balance', error: e);
      rethrow;
    }
  }

  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? notes,
  }) async {
    try {
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
      LoggerService.success(
        'Transfer: $amount from ${accounts[fromIndex].name} to ${accounts[toIndex].name}',
      );
    } catch (e) {
      LoggerService.error('Error transferring between accounts', error: e);
      rethrow;
    }
  }

  Future<AccountModel?> getAccountById(String id) async {
    try {
      final result = await _accountData.getAccount(id);
      final accountData = result['account'];
      if (accountData == null) return null;
      return AccountModel.fromMap(accountData as Map<String, dynamic>);
    } catch (e) {
      LoggerService.error('Error getting account by id', error: e);
      rethrow;
    }
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
    try {
      final accounts = await getAccounts(activeOnly: false);
      final defaultAccount = accounts.where((a) => a.isDefault).firstOrNull;
      return defaultAccount?.id ?? '';
    } catch (e) {
      LoggerService.error('Error getting default account id', error: e);
      rethrow;
    }
  }

  Future<void> setDefaultAccountId(String id) async {
    try {
      await updateAccount(id, {'is_default': true});
    } catch (e) {
      LoggerService.error('Error setting default account', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAccountSummary() async {
    return await _accountData.getAccountSummary();
  }

  /// Calculate available balance (total balance minus goal allocations)
  Future<double> getAvailableBalance() async {
    try {
      final totalBalance = await getTotalBalance();
      final totalGoals = await _goalData.getTotalGoalContributions();
      final available = totalBalance - totalGoals;
      return available < 0 ? 0 : available;
    } catch (e) {
      LoggerService.error('Error calculating available balance', error: e);
      rethrow;
    }
  }

  /// Get contributions for a goal
  Future<List<Map<String, dynamic>>> getGoalContributions(String goalId) async {
    return await _goalData.getGoalContributions(goalId);
  }
}
