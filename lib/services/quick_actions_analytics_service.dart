import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk tracking dan analytics quick actions usage
class QuickActionsAnalyticsService {
  static const String _analyticsKey = 'quick_actions_analytics';
  static const String _preferencesKey = 'quick_actions_preferences';

  /// Track action usage
  Future<void> trackAction(String actionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString(_analyticsKey);
      
      Map<String, dynamic> analytics = {};
      if (analyticsJson != null) {
        analytics = json.decode(analyticsJson) as Map<String, dynamic>;
      }
      
      // Update count
      final count = (analytics[actionId] as num?)?.toInt() ?? 0;
      analytics[actionId] = count + 1;
      analytics['${actionId}_last_used'] = DateTime.now().toIso8601String();
      
      await prefs.setString(_analyticsKey, json.encode(analytics));
      LoggerService.debug('Tracked action: $actionId');
    } catch (e) {
      LoggerService.error('Error tracking action', error: e);
    }
  }

  /// Get action usage count
  Future<int> getActionCount(String actionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString(_analyticsKey);
      
      if (analyticsJson == null) return 0;
      
      final analytics = json.decode(analyticsJson) as Map<String, dynamic>;
      return (analytics[actionId] as num?)?.toInt() ?? 0;
    } catch (e) {
      LoggerService.error('Error getting action count', error: e);
      return 0;
    }
  }

  /// Get most used actions
  Future<List<Map<String, dynamic>>> getMostUsedActions({int limit = 5}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString(_analyticsKey);
      
      if (analyticsJson == null) return [];
      
      final analytics = json.decode(analyticsJson) as Map<String, dynamic>;
      
      // Filter out timestamp entries
      final actionCounts = <String, int>{};
      for (var entry in analytics.entries) {
        if (!entry.key.endsWith('_last_used')) {
          actionCounts[entry.key] = (entry.value as num?)?.toInt() ?? 0;
        }
      }
      
      // Sort by count
      final sorted = actionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sorted.take(limit).map((e) => {
        'id': e.key,
        'count': e.value,
        'last_used': analytics['${e.key}_last_used'],
      }).toList();
    } catch (e) {
      LoggerService.error('Error getting most used actions', error: e);
      return [];
    }
  }

  /// Save quick actions preferences (customizable order, visibility)
  /// Filters out non-encodable fields (IconData, Color, Function) before saving
  Future<void> savePreferences(List<Map<String, dynamic>> actions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Filter out non-encodable fields (IconData, Color, Function)
      final encodableActions = actions.map((action) {
        final sanitized = <String, dynamic>{};
        
        // Only include encodable fields
        if (action.containsKey('id')) sanitized['id'] = action['id'];
        if (action.containsKey('label')) sanitized['label'] = action['label'];
        if (action.containsKey('category')) sanitized['category'] = action['category'];
        if (action.containsKey('visible')) sanitized['visible'] = action['visible'];
        if (action.containsKey('order')) sanitized['order'] = action['order'];
        
        // Store icon as string identifier if available
        if (action.containsKey('icon')) {
          // Try to get icon code point as string identifier
          final icon = action['icon'];
          if (icon != null) {
            // Store icon identifier (will be reconstructed from id when loading)
            sanitized['iconId'] = action['id']; // Use action id to map back to icon
          }
        }
        
        // Store color as hex string if available
        if (action.containsKey('color')) {
          final color = action['color'];
          if (color is Color) {
            sanitized['colorHex'] = '#${color.value.toRadixString(16).padLeft(8, '0')}';
          } else if (color is String) {
            sanitized['colorHex'] = color;
          }
        }
        
        return sanitized;
      }).toList();
      
      await prefs.setString(_preferencesKey, json.encode(encodableActions));
      LoggerService.debug('Saved quick actions preferences');
    } catch (e) {
      LoggerService.error('Error saving preferences', error: e);
    }
  }

  /// Get quick actions preferences
  Future<List<Map<String, dynamic>>> getPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);
      
      if (preferencesJson == null) return [];
      
      final decoded = json.decode(preferencesJson) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      LoggerService.error('Error getting preferences', error: e);
      return [];
    }
  }

  /// Get action categories
  List<String> getActionCategories() {
    return [
      'Navigation',
      'Transactions',
      'Analytics',
      'Settings',
      'Tools',
    ];
  }
}

