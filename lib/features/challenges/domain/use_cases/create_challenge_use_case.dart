import 'package:financial_app/models/challenge_model.dart';
import 'package:financial_app/features/challenges/domain/repositories/challenge_repository_interface.dart';

/// Use case: create a new challenge.
class CreateChallengeUseCase {
  final ChallengeRepositoryInterface _repository;
  CreateChallengeUseCase(this._repository);

  Future<ChallengeModel> call(Map<String, dynamic> data) =>
      _repository.createChallenge(data);
}
