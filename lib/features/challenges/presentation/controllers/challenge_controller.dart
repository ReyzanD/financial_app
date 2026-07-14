import 'package:flutter/foundation.dart';
import 'package:financial_app/models/challenge_model.dart';
import 'package:financial_app/features/challenges/data/repositories/challenge_repository.dart';
import 'package:financial_app/services/logger_service.dart';

/// Controller for the Challenges feature.
class ChallengeController extends ChangeNotifier {
  final ChallengeRepository _repository;

  ChallengeController({required ChallengeRepository repository})
    : _repository = repository;

  List<ChallengeModel> _challenges = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _activeOnly = true;

  List<ChallengeModel> get challenges => _challenges;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get activeOnly => _activeOnly;

  /// Load challenges and compute stats.
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await _repository.getChallenges(activeOnly: _activeOnly);
      _challenges = raw;
      _stats = {
        'active_challenges': _challenges.where((c) => c.isActive).length,
        'total_streak': _challenges.fold<int>(0, (sum, c) => sum + c.streak),
        'completed': _challenges.where((c) => c.isCompleted).length,
      };
    } catch (e) {
      LoggerService.error('ChallengeController.loadData', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh (for RefreshIndicator).
  Future<void> refresh() async => loadData();

  /// Toggle active-only filter.
  void toggleActiveOnly() {
    _activeOnly = !_activeOnly;
    loadData();
  }

  /// Delete challenge and refresh.
  Future<void> deleteChallenge(String id) async {
    try {
      await _repository.deleteChallenge(id);
      await refresh();
    } catch (e) {
      LoggerService.error('ChallengeController.deleteChallenge', error: e);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear error.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
