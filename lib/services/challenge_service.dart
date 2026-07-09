import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/feature_models.dart';

class ChallengeService {
  static const String _challengesKey = 'financial_challenges';
  static const String _challengeDaysKey = 'challenge_days';

  Future<List<ChallengeModel>> getChallenges({bool activeOnly = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = prefs.getString(_challengesKey);
      if (challengesJson == null) return [];

      final List<dynamic> decoded = jsonDecode(challengesJson);
      var challenges =
          decoded
              .map((e) => ChallengeModel.fromJson(e as Map<String, dynamic>))
              .toList();

      return activeOnly
          ? challenges.where((c) => c.isActive).toList()
          : challenges;
    } catch (e) {
      LoggerService.error('Error getting challenges', error: e);
      return [];
    }
  }

  Future<ChallengeModel> createChallenge(ChallengeModel challenge) async {
    try {
      final challenges = await getChallenges(activeOnly: false);
      challenges.add(challenge);
      await _saveChallenges(challenges);
      LoggerService.success('Challenge created: ${challenge.name}');
      return challenge;
    } catch (e) {
      LoggerService.error('Error creating challenge', error: e);
      rethrow;
    }
  }

  Future<ChallengeModel> updateProgress(
    String challengeId,
    double progress,
  ) async {
    try {
      final challenges = await getChallenges(activeOnly: false);
      final index = challenges.indexWhere((c) => c.id == challengeId);
      if (index == -1) throw Exception('Challenge not found');

      final existing = challenges[index];
      challenges[index] = ChallengeModel(
        id: existing.id,
        name: existing.name,
        type: existing.type,
        target: existing.target,
        currentProgress: progress,
        startDate: existing.startDate,
        endDate: existing.endDate,
        isActive: existing.isActive,
        streak: existing.streak,
        bestStreak: existing.bestStreak,
        createdAt: existing.createdAt,
      );

      await _saveChallenges(challenges);
      return challenges[index];
    } catch (e) {
      LoggerService.error('Error updating progress', error: e);
      rethrow;
    }
  }

  Future<void> incrementStreak(String challengeId) async {
    try {
      final challenges = await getChallenges(activeOnly: false);
      final index = challenges.indexWhere((c) => c.id == challengeId);
      if (index == -1) return;

      final existing = challenges[index];
      final newStreak = existing.streak + 1;
      final newBest =
          newStreak > existing.bestStreak ? newStreak : existing.bestStreak;

      challenges[index] = ChallengeModel(
        id: existing.id,
        name: existing.name,
        type: existing.type,
        target: existing.target,
        currentProgress: existing.currentProgress,
        startDate: existing.startDate,
        endDate: existing.endDate,
        isActive: existing.isActive,
        streak: newStreak,
        bestStreak: newBest,
        createdAt: existing.createdAt,
      );

      await _saveChallenges(challenges);

      final today = _dateKey(DateTime.now());
      await _markDayCompleted(challengeId, today);
    } catch (e) {
      LoggerService.error('Error incrementing streak', error: e);
    }
  }

  Future<void> resetStreak(String challengeId) async {
    try {
      final challenges = await getChallenges(activeOnly: false);
      final index = challenges.indexWhere((c) => c.id == challengeId);
      if (index == -1) return;

      challenges[index] = ChallengeModel(
        id: challenges[index].id,
        name: challenges[index].name,
        type: challenges[index].type,
        target: challenges[index].target,
        currentProgress: challenges[index].currentProgress,
        startDate: challenges[index].startDate,
        endDate: challenges[index].endDate,
        isActive: challenges[index].isActive,
        streak: 0,
        bestStreak: challenges[index].bestStreak,
        createdAt: challenges[index].createdAt,
      );

      await _saveChallenges(challenges);
    } catch (e) {
      LoggerService.error('Error resetting streak', error: e);
    }
  }

  Future<List<String>> getCompletedDays(String challengeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_challengeDaysKey}_$challengeId';
      final daysJson = prefs.getString(key);
      if (daysJson == null) return [];

      final List<dynamic> decoded = jsonDecode(daysJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getChallengeStats() async {
    final challenges = await getChallenges();
    final totalStreak = challenges.fold<int>(0, (sum, c) => sum + c.streak);
    final bestStreak = challenges.fold<int>(
      0,
      (max, c) => c.bestStreak > max ? c.bestStreak : max,
    );
    final completed = challenges.where((c) => c.isCompleted).length;

    return {
      'active_challenges': challenges.length,
      'completed_challenges': completed,
      'total_streak': totalStreak,
      'best_streak': bestStreak,
    };
  }

  Future<void> _markDayCompleted(String challengeId, String day) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_challengeDaysKey}_$challengeId';
      final daysJson = prefs.getString(key);
      final List<dynamic> days = daysJson != null ? jsonDecode(daysJson) : [];

      if (!days.contains(day)) {
        days.add(day);
        await prefs.setString(key, jsonEncode(days));
      }
    } catch (e) {
      LoggerService.error('Error marking day completed', error: e);
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveChallenges(List<ChallengeModel> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = challenges.map((c) => c.toJson()).toList();
      await prefs.setString(_challengesKey, jsonEncode(jsonList));
    } catch (e) {
      LoggerService.error('Error saving challenges', error: e);
      rethrow;
    }
  }
}
