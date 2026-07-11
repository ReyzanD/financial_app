import 'package:financial_app/models/challenge_model.dart';

/// Abstract repository for Challenge data operations.
abstract class ChallengeRepositoryInterface {
  Future<List<ChallengeModel>> getChallenges({bool activeOnly = true});
  Future<ChallengeModel> createChallenge(Map<String, dynamic> data);
  Future<void> updateChallenge(String id, Map<String, dynamic> data);
  Future<void> deleteChallenge(String id);
}
