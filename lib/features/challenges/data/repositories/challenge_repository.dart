import 'package:financial_app/models/challenge_model.dart';
import 'package:financial_app/services/data/challenge_data_service.dart';
import 'package:financial_app/features/challenges/domain/repositories/challenge_repository_interface.dart';

/// Challenge Repository Implementation — wraps ChallengeDataService.
class ChallengeRepository implements ChallengeRepositoryInterface {
  final ChallengeDataService _challengeData;

  ChallengeRepository({ChallengeDataService? challengeData})
    : _challengeData = challengeData ?? ChallengeDataService();

  @override
  Future<List<ChallengeModel>> getChallenges({bool activeOnly = true}) async {
    final rows = await _challengeData.getChallenges(activeOnly: activeOnly);
    return rows.map((e) => ChallengeModel.fromMap(e)).toList();
  }

  @override
  Future<ChallengeModel> createChallenge(Map<String, dynamic> data) async {
    final result = await _challengeData.addChallenge(data);
    final saved = result['challenge'] as Map<String, dynamic>? ?? data;
    return ChallengeModel.fromMap(saved);
  }

  @override
  Future<void> updateChallenge(String id, Map<String, dynamic> data) async {
    await _challengeData.updateChallenge(id, data);
  }

  @override
  Future<void> deleteChallenge(String id) async {
    await _challengeData.deleteChallenge(id);
  }
}
