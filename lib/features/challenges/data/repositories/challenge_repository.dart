import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/challenge_model.dart';
import 'package:financial_app/services/data/challenge_data_service.dart';

/// Challenge Repository Implementation — wraps ChallengeDataService.
class ChallengeRepository {
  final ChallengeDataService _challengeData;

  ChallengeRepository({ChallengeDataService? challengeData})
    : _challengeData = challengeData ?? getIt<ChallengeDataService>();

  Future<List<ChallengeModel>> getChallenges({bool activeOnly = true}) async {
    return _challengeData.getChallenges(activeOnly: activeOnly);
  }

  Future<ChallengeModel> createChallenge(Map<String, dynamic> data) async {
    return _challengeData.addChallenge(data);
  }

  Future<void> updateChallenge(String id, Map<String, dynamic> data) async {
    await _challengeData.updateChallenge(id, data);
  }

  Future<void> deleteChallenge(String id) async {
    await _challengeData.deleteChallenge(id);
  }
}
