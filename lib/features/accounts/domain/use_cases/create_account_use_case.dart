import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/features/accounts/domain/repositories/account_repository_interface.dart';

/// Use case: create a new account.
class CreateAccountUseCase {
  final AccountRepositoryInterface _repository;

  CreateAccountUseCase(this._repository);

  Future<AccountModel> call(AccountModel account) =>
      _repository.createAccount(account);
}
