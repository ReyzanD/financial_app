import 'package:flutter/foundation.dart';
import 'package:financial_app/features/goals/domain/entities/goal_entity.dart';
import 'package:financial_app/features/goals/domain/repositories/goal_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

/// Controller for the Goals feature.
class GoalController extends ChangeNotifier {
  final GoalRepositoryInterface _repository;

  GoalController({required GoalRepositoryInterface repository}) : _repository = repository;

  List<GoalEntity> _goals = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<GoalEntity> get goals => _goals;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load goals and summary.
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _repository.getGoals();
      _summary = await _repository.getSummary();
    } catch (e) {
      LoggerService.error('GoalController.loadData', error: e);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh (same as loadData but also returns a future for RefreshIndicator).
  Future<void> refresh() async {
    await loadData();
  }

  /// Delete a goal and refresh.
  Future<void> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      await refresh();
    } catch (e) {
      LoggerService.error('GoalController.deleteGoal', error: e);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Create a goal and refresh.
  Future<bool> createGoal(GoalEntity goal) async {
    try {
      await _repository.createGoal(goal);
      await refresh();
      return true;
    } catch (e) {
      LoggerService.error('GoalController.createGoal', error: e);
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
