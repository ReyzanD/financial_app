import 'package:financial_app/models/account_model.dart';

/// Abstract repository for Account data operations.
abstract class AccountRepositoryInterface {
  Future<List<AccountModel>> getAccounts({bool activeOnly = true});
  Future<AccountModel> createAccount(AccountModel account);
  Future<AccountModel> updateAccount(String id, Map<String, dynamic> updates);
  Future<void> deleteAccount(String id);
  Future<double> getTotalBalance();
  Future<Map<String, double>> getTotalBalanceByType();
  Future<AccountModel?> getAccountById(String id);
  Future<String> getDefaultAccountId();
  Future<Map<String, dynamic>> getAccountSummary();
  Future<void> adjustBalance(String id, double amount, {String? notes});
  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? notes,
  });
}
