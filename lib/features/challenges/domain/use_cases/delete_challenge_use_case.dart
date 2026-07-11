import 'package:financial_app/features/challenges/domain/repositories/challenge_repository_interface.dart';

/// Use case: delete a challenge by id.
class DeleteChallengeUseCase {
  final ChallengeRepositoryInterface _repository;
  DeleteChallengeUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteChallenge(id);
}
