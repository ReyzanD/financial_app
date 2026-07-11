import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/features/accounts/domain/repositories/account_repository_interface.dart';

/// Use case: retrieve all accounts (optionally active only).
class GetAccountsUseCase {
  final AccountRepositoryInterface _repository;

  GetAccountsUseCase(this._repository);

  Future<List<AccountModel>> call({bool activeOnly = true}) =>
      _repository.getAccounts(activeOnly: activeOnly);
}
