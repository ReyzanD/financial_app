import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:financial_app/services/logger_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to relevant screen
    LoggerService.debug('Notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Show instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'financial_app_channel',
          'Financial Notifications',
          channelDescription: 'Notifications for financial updates',
          importance: _getAndroidImportance(priority),
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Schedule notification for specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_channel',
          'Scheduled Notifications',
          channelDescription: 'Scheduled financial reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule daily notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required NotificationServiceTimeOfDay time,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If scheduled time is in the past, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Notifications',
          channelDescription: 'Daily financial summaries',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Budget Alert Notifications
  Future<void> sendBudgetAlert({
    required String categoryName,
    required double percentage,
    required double spent,
    required double limit,
  }) async {
    String title;
    String body;
    NotificationPriority priority;

    if (percentage >= 100) {
      title = '🚨 Budget Exceeded!';
      body =
          '$categoryName: Rp ${spent.toStringAsFixed(0)} / Rp ${limit.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)';
      priority = NotificationPriority.max;
    } else if (percentage >= 90) {
      title = '⚠️ Budget Alert!';
      body =
          '$categoryName: ${percentage.toStringAsFixed(0)}% used. Only Rp ${(limit - spent).toStringAsFixed(0)} left.';
      priority = NotificationPriority.high;
    } else if (percentage >= 80) {
      title = '📊 Budget Warning';
      body = '$categoryName budget is ${percentage.toStringAsFixed(0)}% full.';
      priority = NotificationPriority.medium;
    } else {
      return; // Don't send notification below 80%
    }

    await showNotification(
      id: categoryName.hashCode,
      title: title,
      body: body,
      priority: priority,
      payload: 'budget:$categoryName',
    );
  }

  /// Bill Reminder Notifications
  Future<void> scheduleBillReminder({
    required String billName,
    required double amount,
    required DateTime dueDate,
    required int daysBeforeReminder,
  }) async {
    final reminderDate = dueDate.subtract(Duration(days: daysBeforeReminder));

    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: billName.hashCode + daysBeforeReminder,
        title: '💰 Bill Reminder',
        body:
            '$billName due in $daysBeforeReminder days: Rp ${amount.toStringAsFixed(0)}',
        scheduledDate: reminderDate,
        payload: 'bill:$billName',
      );
    }
  }

  /// Goal Achievement Notifications
  Future<void> sendGoalAchievement({
    required String goalName,
    required double achieved,
    required double target,
    required double percentage,
  }) async {
    String title;
    String body;

    if (percentage >= 100) {
      title = '🎉 Goal Achieved!';
      body = 'Congratulations! You\'ve reached your goal: $goalName';
    } else if (percentage >= 75) {
      title = '🎯 Almost There!';
      body =
          '$goalName: ${percentage.toStringAsFixed(0)}% complete. Keep going!';
    } else if (percentage >= 50) {
      title = '📈 Halfway There!';
      body = '$goalName: ${percentage.toStringAsFixed(0)}% complete.';
    } else if (percentage >= 25) {
      title = '💪 Good Progress!';
      body = '$goalName: ${percentage.toStringAsFixed(0)}% complete.';
    } else {
      return; // Don't send below 25%
    }

    await showNotification(
      id: goalName.hashCode,
      title: title,
      body: body,
      priority: NotificationPriority.high,
      payload: 'goal:$goalName',
    );
  }

  /// Daily Summary Notification
  Future<void> sendDailySummary({
    required double totalIncome,
    required double totalExpense,
    required int transactionCount,
  }) async {
    final balance = totalIncome - totalExpense;
    final balanceText =
        balance >= 0
            ? '+Rp ${balance.toStringAsFixed(0)}'
            : '-Rp ${balance.abs().toStringAsFixed(0)}';

    await showNotification(
      id: 999,
      title: '📊 Daily Summary',
      body: '$transactionCount transactions today. Balance: $balanceText',
      priority: NotificationPriority.medium,
      payload: 'summary:daily',
    );
  }

  /// Weekly Summary Notification
  Future<void> sendWeeklySummary({
    required double totalIncome,
    required double totalExpense,
    required int transactionCount,
    required String topCategory,
  }) async {
    final balance = totalIncome - totalExpense;

    await showNotification(
      id: 998,
      title: '📈 Weekly Summary',
      body:
          '$transactionCount transactions. Top spending: $topCategory. Balance: Rp ${balance.toStringAsFixed(0)}',
      priority: NotificationPriority.medium,
      payload: 'summary:weekly',
    );
  }

  /// Recurring Transaction Reminder
  Future<void> sendRecurringReminder({
    required String transactionName,
    required double amount,
    required String type,
  }) async {
    final emoji = type == 'income' ? '💰' : '💸';

    await showNotification(
      id: transactionName.hashCode,
      title: '$emoji Recurring Transaction',
      body: '$transactionName: Rp ${amount.toStringAsFixed(0)}',
      priority: NotificationPriority.medium,
      payload: 'recurring:$transactionName',
    );
  }

  /// AI Insight Notification
  Future<void> sendAIInsight({
    required String insight,
    required double potentialSavings,
  }) async {
    await showNotification(
      id: 997,
      title: '💡 AI Insight',
      body: insight,
      priority: NotificationPriority.medium,
      payload: 'ai:insight',
    );
  }

  /// Subscription Renewal Notification
  Future<void> scheduleSubscriptionRenewal({
    required String name,
    required double cost,
    required DateTime renewalDate,
    required String cycle,
  }) async {
    final reminderDate = renewalDate.subtract(const Duration(days: 1));

    if (reminderDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: 'sub_renewal_$name'.hashCode,
        title: '🔄 Subscription Renewal',
        body: '$name renews tomorrow: Rp ${cost.toStringAsFixed(0)}/$cycle',
        scheduledDate: reminderDate,
        payload: 'subscription:$name',
      );
    }
  }

  /// Cancel subscription renewal notification
  Future<void> cancelSubscriptionRenewal(String name) async {
    await cancelNotification('sub_renewal_$name'.hashCode);
  }

  /// Challenge Deadline Notification
  Future<void> scheduleChallengeReminder({
    required String name,
    required DateTime endDate,
    required double progress,
    required double target,
  }) async {
    final daysLeft = endDate.difference(DateTime.now()).inDays;

    if (daysLeft > 0 && daysLeft <= 3) {
      final percentage =
          target > 0 ? (progress / target * 100).toStringAsFixed(0) : '0';

      await scheduleNotification(
        id: 'challenge_$name'.hashCode,
        title: '⏰ Challenge Ending',
        body: '$name ends in $daysLeft days. Progress: $percentage%',
        scheduledDate: DateTime.now().add(const Duration(hours: 1)),
        payload: 'challenge:$name',
      );
    }
  }

  /// Challenge Completion Notification
  Future<void> sendChallengeCompleted({
    required String name,
    required double progress,
    required double target,
  }) async {
    await showNotification(
      id: 'challenge_complete_$name'.hashCode,
      title: '🏆 Challenge Complete!',
      body:
          'Congratulations! You completed "$name" with Rp ${progress.toStringAsFixed(0)} / Rp ${target.toStringAsFixed(0)}',
      priority: NotificationPriority.max,
      payload: 'challenge_complete:$name',
    );
  }

  /// Debt Payment Reminder
  Future<void> scheduleDebtPaymentReminder({
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    final daysLeft = dueDate.difference(DateTime.now()).inDays;

    if (daysLeft > 0 && daysLeft <= 7) {
      await scheduleNotification(
        id: 'debt_$name'.hashCode,
        title: '💳 Debt Payment Reminder',
        body:
            '$name payment due in $daysLeft days: Rp ${amount.toStringAsFixed(0)}',
        scheduledDate: dueDate.subtract(const Duration(days: 1)),
        payload: 'debt:$name',
      );
    }
  }

  /// Split Payment Reminder
  Future<void> sendSplitPaymentReminder({
    required String participantName,
    required double amount,
    required String description,
  }) async {
    await showNotification(
      id: 'split_$participantName'.hashCode,
      title: '💸 Split Payment Reminder',
      body:
          '$participantName owes you Rp ${amount.toStringAsFixed(0)} for $description',
      priority: NotificationPriority.medium,
      payload: 'split:$participantName',
    );
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Helper: Convert priority to Android importance
  Importance _getAndroidImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.max:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.medium:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }
}

/// Notification Priority Levels
enum NotificationPriority { max, high, medium, low }

/// Time of Day helper
class NotificationServiceTimeOfDay {
  final int hour;
  final int minute;

  const NotificationServiceTimeOfDay({
    required this.hour,
    required this.minute,
  });
}
