import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistoryService {
  static const String _historyKey = 'notification_history';
  static const int _maxHistoryItems = 50;

  /// Add notification to history
  Future<void> addToHistory({
    required String title,
    required String body,
    required String type,
    DateTime? timestamp,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'type': type,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'read': false,
    };

    history.insert(0, notification);

    // Keep only last N items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await prefs.setString(_historyKey, json.encode(history));
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    if (historyJson == null) return [];

    final List<dynamic> decoded = json.decode(historyJson);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final history = await getHistory();
    return history.where((n) => n['read'] == false).length;
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    final index = history.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      history[index]['read'] = true;
      await prefs.setString(_historyKey, json.encode(history));
    }
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    for (var notification in history) {
      notification['read'] = true;
    }

    await prefs.setString(_historyKey, json.encode(history));
  }

  /// Clear history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Delete specific notification
  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere((n) => n['id'] == id);
    await prefs.setString(_historyKey, json.encode(history));
  }

  /// Get icon for notification type
  String getIconForType(String type) {
    switch (type) {
      case 'budget':
        return '🚨';
      case 'bill':
        return '💰';
      case 'goal':
        return '🎯';
      case 'summary':
        return '📊';
      case 'ai':
        return '💡';
      case 'recurring':
        return '🔄';
      default:
        return '🔔';
    }
  }

  /// Get color for notification type
  int getColorForType(String type) {
    switch (type) {
      case 'budget':
        return 0xFFE53935; // Red
      case 'bill':
        return 0xFFFFA726; // Orange
      case 'goal':
        return 0xFF8B5FBF; // Purple
      case 'summary':
        return 0xFF42A5F5; // Blue
      case 'ai':
        return 0xFF66BB6A; // Green
      case 'recurring':
        return 0xFF78909C; // Grey
      default:
        return 0xFF8B5FBF; // Default purple
    }
  }
}
