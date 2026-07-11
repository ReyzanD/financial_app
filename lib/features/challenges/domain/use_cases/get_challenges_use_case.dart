import 'package:financial_app/models/challenge_model.dart';
import 'package:financial_app/features/challenges/domain/repositories/challenge_repository_interface.dart';

/// Use case: retrieve challenges (optionally active only).
class GetChallengesUseCase {
  final ChallengeRepositoryInterface _repository;
  GetChallengesUseCase(this._repository);

  Future<List<ChallengeModel>> call({bool activeOnly = true}) =>
      _repository.getChallenges(activeOnly: activeOnly);
}
