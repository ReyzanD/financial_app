import 'package:financial_app/features/accounts/domain/repositories/account_repository_interface.dart';

/// Use case: delete an account by id.
class DeleteAccountUseCase {
  final AccountRepositoryInterface _repository;

  DeleteAccountUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteAccount(id);
}
