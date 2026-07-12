import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/features/accounts/domain/repositories/account_repository_interface.dart';

/// Account Repository Implementation — wraps AccountService.
class AccountRepository implements AccountRepositoryInterface {
  final AccountService _accountService;

  AccountRepository({AccountService? accountService})
    : _accountService = accountService ?? AccountService();

  @override
  Future<List<AccountModel>> getAccounts({bool activeOnly = true}) async {
    return await _accountService.getAccounts(activeOnly: activeOnly);
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    return await _accountService.createAccount(account);
  }

  @override
  Future<AccountModel> updateAccount(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return await _accountService.updateAccount(id, updates);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _accountService.deleteAccount(id);
  }

  @override
  Future<double> getTotalBalance() async {
    return await _accountService.getTotalBalance();
  }

  @override
  Future<Map<String, double>> getTotalBalanceByType() async {
    return await _accountService.getTotalBalanceByType();
  }

  @override
  Future<AccountModel?> getAccountById(String id) async {
    return await _accountService.getAccountById(id);
  }

  @override
  Future<String> getDefaultAccountId() async {
    return await _accountService.getDefaultAccountId();
  }

  @override
  Future<Map<String, dynamic>> getAccountSummary() async {
    return await _accountService.getAccountSummary();
  }

  @override
  Future<void> adjustBalance(String id, double amount, {String? notes}) async {
    await _accountService.adjustBalance(id, amount, notes: notes);
  }

  @override
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
