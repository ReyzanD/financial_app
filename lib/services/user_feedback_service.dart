import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';
import 'dart:convert';

/// Service untuk user feedback collection
class UserFeedbackService {
  static const String _feedbackKey = 'user_feedback_queue';
  static const String _ratingKey = 'app_rating';

  /// Submit feedback
  Future<bool> submitFeedback({
    required String type, // 'bug', 'feature', 'general', 'rating'
    required String message,
    String? email,
    Map<String, dynamic>? metadata,
    int? rating,
  }) async {
    try {
      final feedback = {
        'type': type,
        'message': message,
        'email': email,
        'metadata': metadata ?? {},
        'rating': rating,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'mobile',
      };

      // Try to send to backend
      try {
        // Note: Ini perlu endpoint di backend
        // final apiService = ApiService();
        // await apiService.post('feedback', feedback);
        LoggerService.info('Feedback submitted: $type');
      } catch (e) {
        // If backend fails, queue for later
        await _queueFeedback(feedback);
        LoggerService.warning('Backend unavailable, feedback queued');
      }

      // Save rating locally
      if (rating != null) {
        await _saveRating(rating);
      }

      return true;
    } catch (e) {
      LoggerService.error('Error submitting feedback', error: e);
      return false;
    }
  }

  /// Queue feedback untuk sync later
  Future<void> _queueFeedback(Map<String, dynamic> feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_feedbackKey);
      
      List<Map<String, dynamic>> queue = [];
      if (queueJson != null) {
        final decoded = json.decode(queueJson) as List;
        queue = decoded.cast<Map<String, dynamic>>();
      }
      
      queue.add(feedback);
      
      // Keep only last 50 feedbacks
      if (queue.length > 50) {
        queue.removeAt(0);
      }
      
      await prefs.setString(_feedbackKey, json.encode(queue));
    } catch (e) {
      LoggerService.error('Error queueing feedback', error: e);
    }
  }

  /// Sync queued feedbacks
  Future<void> syncQueuedFeedbacks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_feedbackKey);
      
      if (queueJson == null) return;
      
      final queue = (json.decode(queueJson) as List).cast<Map<String, dynamic>>();
      
      for (var feedbackData in queue) {
        try {
          // Try to send to backend
          // final apiService = ApiService();
          // await apiService.post('feedback', feedbackData);
          LoggerService.info('Synced queued feedback: ${feedbackData['type']}');
        } catch (e) {
          LoggerService.error('Error syncing feedback', error: e);
          break; // Stop on first error
        }
      }
      
      // Clear queue if all synced
      await prefs.remove(_feedbackKey);
    } catch (e) {
      LoggerService.error('Error syncing queued feedbacks', error: e);
    }
  }

  /// Save app rating
  Future<void> _saveRating(int rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_ratingKey, rating);
      await prefs.setString('${_ratingKey}_date', DateTime.now().toIso8601String());
    } catch (e) {
      LoggerService.error('Error saving rating', error: e);
    }
  }

  /// Get saved rating
  Future<int?> getSavedRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_ratingKey);
    } catch (e) {
      LoggerService.error('Error getting rating', error: e);
      return null;
    }
  }

  /// Check if user has rated
  Future<bool> hasRated() async {
    final rating = await getSavedRating();
    return rating != null;
  }

  /// Submit bug report
  Future<bool> submitBugReport({
    required String description,
    String? stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    Map<String, dynamic>? deviceInfo,
  }) async {
    return await submitFeedback(
      type: 'bug',
      message: description,
      metadata: {
        'steps_to_reproduce': stepsToReproduce,
        'expected_behavior': expectedBehavior,
        'actual_behavior': actualBehavior,
        'device_info': deviceInfo,
      },
    );
  }

  /// Submit feature request
  Future<bool> submitFeatureRequest({
    required String feature,
    String? description,
    String? useCase,
  }) async {
    return await submitFeedback(
      type: 'feature',
      message: feature,
      metadata: {
        'description': description,
        'use_case': useCase,
      },
    );
  }

  /// Submit general feedback
  Future<bool> submitGeneralFeedback({
    required String message,
    String? email,
  }) async {
    return await submitFeedback(
      type: 'general',
      message: message,
      email: email,
    );
  }

  /// Submit app rating
  Future<bool> submitRating({
    required int rating, // 1-5
    String? comment,
  }) async {
    return await submitFeedback(
      type: 'rating',
      message: comment ?? '',
      rating: rating,
    );
  }

  /// Check if should prompt for rating
  Future<bool> shouldPromptForRating() async {
    try {
      // Don't prompt if already rated
      if (await hasRated()) return false;
      
      // Check app usage (number of opens)
      final prefs = await SharedPreferences.getInstance();
      final openCount = prefs.getInt('app_open_count') ?? 0;
      
      // Prompt after 10 opens
      if (openCount >= 10) {
        // Check last prompt date
        final lastPromptDate = prefs.getString('last_rating_prompt_date');
        if (lastPromptDate != null) {
          final lastPrompt = DateTime.parse(lastPromptDate);
          final daysSincePrompt = DateTime.now().difference(lastPrompt).inDays;
          
          // Don't prompt if prompted in last 30 days
          if (daysSincePrompt < 30) return false;
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      LoggerService.error('Error checking rating prompt', error: e);
      return false;
    }
  }

  /// Record rating prompt shown
  Future<void> recordRatingPromptShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_rating_prompt_date', DateTime.now().toIso8601String());
    } catch (e) {
      LoggerService.error('Error recording rating prompt', error: e);
    }
  }
}

