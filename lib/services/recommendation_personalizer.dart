import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service for personalizing recommendations based on user feedback and behavior
class RecommendationPersonalizer {
  static const String _prefsKey = 'recommendation_feedback';
  static const String _actionKey = 'recommendation_actions';

  /// Track user feedback on a recommendation
  Future<void> trackFeedback({
    required String recommendationId,
    required String recommendationType,
    required String action, // 'dismissed', 'acted_on', 'ignored', 'helpful'
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackData = prefs.getString(_prefsKey);
      
      Map<String, dynamic> feedback;
      if (feedbackData != null) {
        feedback = Map<String, dynamic>.from(
          jsonDecode(feedbackData) as Map,
        );
      } else {
        feedback = {};
      }

      // Initialize type tracking if needed
      if (!feedback.containsKey(recommendationType)) {
        feedback[recommendationType] = {
          'total_shown': 0,
          'dismissed': 0,
          'acted_on': 0,
          'ignored': 0,
          'helpful': 0,
          'success_rate': 0.0,
        };
      }

      final typeData = feedback[recommendationType] as Map<String, dynamic>;
      typeData['total_shown'] = (typeData['total_shown'] as int? ?? 0) + 1;

      // Update action counts
      if (action == 'dismissed') {
        typeData['dismissed'] = (typeData['dismissed'] as int? ?? 0) + 1;
      } else if (action == 'acted_on') {
        typeData['acted_on'] = (typeData['acted_on'] as int? ?? 0) + 1;
      } else if (action == 'ignored') {
        typeData['ignored'] = (typeData['ignored'] as int? ?? 0) + 1;
      } else if (action == 'helpful') {
        typeData['helpful'] = (typeData['helpful'] as int? ?? 0) + 1;
      }

      // Calculate success rate (acted_on + helpful) / total_shown
      final totalShown = typeData['total_shown'] as int;
      final positiveActions = (typeData['acted_on'] as int? ?? 0) + 
                             (typeData['helpful'] as int? ?? 0);
      typeData['success_rate'] = totalShown > 0 
          ? positiveActions / totalShown 
          : 0.0;

      // Track individual recommendation
      if (!feedback.containsKey('recommendations')) {
        feedback['recommendations'] = {};
      }
      final recommendations = feedback['recommendations'] as Map<String, dynamic>;
      if (!recommendations.containsKey(recommendationId)) {
        recommendations[recommendationId] = {
          'type': recommendationType,
          'actions': [],
        };
      }
      final recData = recommendations[recommendationId] as Map<String, dynamic>;
      final actions = recData['actions'] as List<dynamic>;
      actions.add({
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_prefsKey, jsonEncode(feedback));
      
      final successRatePercent = ((typeData['success_rate'] as double? ?? 0.0) * 100).toStringAsFixed(1);
      LoggerService.debug(
        'Tracked feedback: $recommendationType - $action (Success rate: $successRatePercent%)',
      );
    } catch (e) {
      LoggerService.error('Error tracking recommendation feedback', error: e);
    }
  }

  /// Get success rate for a recommendation type
  Future<double> getSuccessRate(String recommendationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackData = prefs.getString(_prefsKey);
      
      if (feedbackData == null) return 0.5; // Default neutral score

      final feedback = Map<String, dynamic>.from(jsonDecode(feedbackData) as Map);
      final typeData = feedback[recommendationType] as Map<String, dynamic>?;
      
      if (typeData == null) return 0.5;
      
      return typeData['success_rate'] as double? ?? 0.5;
    } catch (e) {
      LoggerService.error('Error getting success rate', error: e);
      return 0.5;
    }
  }

  /// Personalize recommendation order based on user preferences
  Future<List<Map<String, dynamic>>> personalizeRecommendations(
    List<Map<String, dynamic>> recommendations,
  ) async {
    try {
      // Get success rates for each recommendation type
      final personalizedRecs = <Map<String, dynamic>>[];

      for (var rec in recommendations) {
        final recType = rec['category'] as String? ?? rec['type'] as String? ?? 'general';
        final successRate = await getSuccessRate(recType);
        
        // Add personalization score
        final personalizedRec = Map<String, dynamic>.from(rec);
        personalizedRec['personalization_score'] = successRate;
        
        // Adjust overall score with personalization (30% weight)
        final currentScore = rec['score'] as double? ?? rec['confidence'] as double? ?? 0.5;
        final personalizedScore = (currentScore * 0.7) + (successRate * 0.3);
        personalizedRec['final_score'] = personalizedScore;
        
        personalizedRecs.add(personalizedRec);
      }

      // Sort by final score (highest first)
      personalizedRecs.sort((a, b) {
        final scoreA = a['final_score'] as double? ?? 0.0;
        final scoreB = b['final_score'] as double? ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

      return personalizedRecs;
    } catch (e) {
      LoggerService.error('Error personalizing recommendations', error: e);
      return recommendations; // Return original if error
    }
  }

  /// Infer user preferences from behavior
  Future<Map<String, dynamic>> inferPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackData = prefs.getString(_prefsKey);
      
      if (feedbackData == null) {
        return {
          'preferred_types': [],
          'avoided_types': [],
          'engagement_level': 'medium',
        };
      }

      final feedback = Map<String, dynamic>.from(jsonDecode(feedbackData) as Map);
      final preferences = <String, dynamic>{};
      final preferredTypes = <String>[];
      final avoidedTypes = <String>[];

      feedback.forEach((type, data) {
        if (type == 'recommendations') return;
        
        final typeData = data as Map<String, dynamic>;
        final successRate = typeData['success_rate'] as double? ?? 0.0;
        
        if (successRate > 0.6) {
          preferredTypes.add(type);
        } else if (successRate < 0.3) {
          avoidedTypes.add(type);
        }
      });

      // Calculate engagement level
      int totalShown = 0;
      int totalActions = 0;
      feedback.forEach((type, data) {
        if (type == 'recommendations') return;
        final typeData = data as Map<String, dynamic>;
        totalShown += typeData['total_shown'] as int? ?? 0;
        totalActions += (typeData['acted_on'] as int? ?? 0) + 
                       (typeData['helpful'] as int? ?? 0);
      });

      String engagementLevel;
      if (totalShown == 0) {
        engagementLevel = 'low';
      } else {
        final engagementRate = totalActions / totalShown;
        if (engagementRate > 0.5) {
          engagementLevel = 'high';
        } else if (engagementRate > 0.2) {
          engagementLevel = 'medium';
        } else {
          engagementLevel = 'low';
        }
      }

      preferences['preferred_types'] = preferredTypes;
      preferences['avoided_types'] = avoidedTypes;
      preferences['engagement_level'] = engagementLevel;
      preferences['total_recommendations_shown'] = totalShown;
      preferences['total_actions_taken'] = totalActions;

      return preferences;
    } catch (e) {
      LoggerService.error('Error inferring preferences', error: e);
      return {
        'preferred_types': [],
        'avoided_types': [],
        'engagement_level': 'medium',
      };
    }
  }

  /// Clear all feedback data (for testing or reset)
  Future<void> clearFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      await prefs.remove(_actionKey);
      LoggerService.debug('Cleared recommendation feedback data');
    } catch (e) {
      LoggerService.error('Error clearing feedback', error: e);
    }
  }

}

