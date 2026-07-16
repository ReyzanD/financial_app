import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/services/account_service.dart';

/// Account Repository Implementation — wraps AccountService.
class AccountRepository {
  final AccountService _accountService;

  AccountRepository({AccountService? accountService}) : _accountService = accountService ?? getIt<AccountService>();

  Future<List<AccountModel>> getAccounts({bool activeOnly = true}) async {
    return await _accountService.getAccounts(activeOnly: activeOnly);
  }

  Future<AccountModel> createAccount(AccountModel account) async {
    return await _accountService.createAccount(account);
  }

  Future<AccountModel> updateAccount(String id, Map<String, dynamic> updates) async {
    return await _accountService.updateAccount(id, updates);
  }

  Future<void> deleteAccount(String id) async {
    await _accountService.deleteAccount(id);
  }

  Future<double> getTotalBalance() async {
    return await _accountService.getTotalBalance();
  }

  Future<Map<String, double>> getTotalBalanceByType() async {
    return await _accountService.getTotalBalanceByType();
  }

  Future<AccountModel?> getAccountById(String id) async {
    return await _accountService.getAccountById(id);
  }

  Future<String> getDefaultAccountId() async {
    return await _accountService.getDefaultAccountId();
  }

  Future<Map<String, dynamic>> getAccountSummary() async {
    return await _accountService.getAccountSummary();
  }

  Future<void> adjustBalance(String id, double amount, {String? notes}) async {
    await _accountService.adjustBalance(id, amount, notes: notes);
  }

  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? notes,
  }) async {
    await _accountService.transferBetweenAccounts(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      notes: notes,
    );
  }
}
