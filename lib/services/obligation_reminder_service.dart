import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola reminder tagihan dengan smart scheduling
class ObligationReminderService {
  final NotificationService _notificationService = NotificationService();
  final ObligationService _obligationService = ObligationService();

  /// Schedule reminders untuk semua active obligations
  Future<void> scheduleAllReminders() async {
    try {
      LoggerService.info('[ObligationReminderService] Scheduling all reminders...');
      
      final obligations = await _obligationService.getObligations();
      
      for (var obligation in obligations) {
        await scheduleReminderForObligation(obligation);
      }
      
      LoggerService.success('[ObligationReminderService] All reminders scheduled');
    } catch (e) {
      LoggerService.error('[ObligationReminderService] Error scheduling reminders', error: e);
    }
  }

  /// Schedule reminder untuk satu obligation
  Future<void> scheduleReminderForObligation(
    FinancialObligation obligation,
  ) async {
    try {
      // Check if reminders are enabled for this obligation
      final remindersEnabled = await getReminderEnabled(obligation.id);
      if (!remindersEnabled) {
        LoggerService.debug('[ObligationReminderService] Reminders disabled for ${obligation.name}');
        return;
      }

      // Get reminder days before due date
      final reminderDays = await getReminderDays(obligation.id);
      
      // Calculate reminder date
      final reminderDate = obligation.dueDate.subtract(Duration(days: reminderDays));
      
      // Only schedule if reminder date is in the future
      if (reminderDate.isAfter(DateTime.now())) {
        await _notificationService.scheduleBillReminder(
          billName: obligation.name,
          amount: obligation.monthlyAmount,
          dueDate: obligation.dueDate,
          daysBeforeReminder: reminderDays,
        );
        
        LoggerService.debug(
          '[ObligationReminderService] Scheduled reminder for ${obligation.name} on ${reminderDate.toString()}',
        );
      }

      // Also schedule overdue reminder if bill is already overdue
      if (obligation.daysUntilDue < 0) {
        await _scheduleOverdueReminder(obligation);
      }
    } catch (e) {
      LoggerService.error(
        '[ObligationReminderService] Error scheduling reminder for ${obligation.name}',
        error: e,
      );
    }
  }

  /// Schedule overdue reminder
  Future<void> _scheduleOverdueReminder(FinancialObligation obligation) async {
    try {
      // Schedule immediate overdue notification
      await _notificationService.scheduleNotification(
        id: 'overdue_${obligation.id}'.hashCode,
        title: '⚠️ Tagihan Terlambat',
        body: '${obligation.name} sudah jatuh tempo! Jumlah: Rp ${obligation.monthlyAmount.toStringAsFixed(0)}',
        scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
        payload: 'obligation:${obligation.id}:overdue',
      );
    } catch (e) {
      LoggerService.error('Error scheduling overdue reminder', error: e);
    }
  }

  /// Cancel reminder untuk obligation
  Future<void> cancelReminder(String obligationId) async {
    try {
      final obligations = await _obligationService.getObligations();
      final obligation = obligations.firstWhere(
        (o) => o.id == obligationId,
        orElse: () => throw Exception('Obligation not found'),
      );

      // Cancel all reminder notifications for this obligation
      final reminderDays = await getReminderDays(obligationId);
      final notificationId = '${obligation.name}_$reminderDays'.hashCode;
      
      await _notificationService.cancelNotification(notificationId);
      
      LoggerService.debug('[ObligationReminderService] Cancelled reminder for ${obligation.name}');
    } catch (e) {
      LoggerService.error('Error cancelling reminder', error: e);
    }
  }

  /// Get reminder enabled status untuk obligation
  Future<bool> getReminderEnabled(String obligationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('obligation_reminder_$obligationId') ?? true;
    } catch (e) {
      LoggerService.error('Error getting reminder enabled status', error: e);
      return true; // Default to enabled
    }
  }

  /// Set reminder enabled status
  Future<void> setReminderEnabled(String obligationId, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('obligation_reminder_$obligationId', enabled);
      
      if (enabled) {
        // Reschedule reminder if enabling
        final obligations = await _obligationService.getObligations();
        final obligation = obligations.firstWhere(
          (o) => o.id == obligationId,
          orElse: () => throw Exception('Obligation not found'),
        );
        await scheduleReminderForObligation(obligation);
      } else {
        // Cancel reminder if disabling
        await cancelReminder(obligationId);
      }
    } catch (e) {
      LoggerService.error('Error setting reminder enabled status', error: e);
    }
  }

  /// Get reminder days before due date
  Future<int> getReminderDays(String obligationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('obligation_reminder_days_$obligationId') ?? 3;
    } catch (e) {
      LoggerService.error('Error getting reminder days', error: e);
      return 3; // Default to 3 days
    }
  }

  /// Set reminder days before due date
  Future<void> setReminderDays(String obligationId, int days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('obligation_reminder_days_$obligationId', days);
      
      // Reschedule reminder with new days
      final obligations = await _obligationService.getObligations();
      final obligation = obligations.firstWhere(
        (o) => o.id == obligationId,
        orElse: () => throw Exception('Obligation not found'),
      );
      
      // Cancel old reminder
      await cancelReminder(obligationId);
      
      // Schedule new reminder
      await scheduleReminderForObligation(obligation);
    } catch (e) {
      LoggerService.error('Error setting reminder days', error: e);
    }
  }

  /// Get upcoming reminders (bills due soon)
  Future<List<Map<String, dynamic>>> getUpcomingReminders({int days = 7}) async {
    try {
      final obligations = await _obligationService.getUpcomingObligations(days: days);
      final reminders = <Map<String, dynamic>>[];

      for (var obligation in obligations) {
        final remindersEnabled = await getReminderEnabled(obligation.id);
        if (remindersEnabled) {
          reminders.add({
            'obligation': obligation,
            'dueDate': obligation.dueDate,
            'daysUntilDue': obligation.daysUntilDue,
            'amount': obligation.monthlyAmount,
          });
        }
      }

      return reminders;
    } catch (e) {
      LoggerService.error('Error getting upcoming reminders', error: e);
      return [];
    }
  }

  /// Snooze reminder (reschedule for later)
  Future<void> snoozeReminder(String obligationId, {int hours = 24}) async {
    try {
      final obligations = await _obligationService.getObligations();
      final obligation = obligations.firstWhere(
        (o) => o.id == obligationId,
        orElse: () => throw Exception('Obligation not found'),
      );

      // Schedule new reminder for later
      await _notificationService.scheduleNotification(
        id: 'snooze_${obligation.id}_${DateTime.now().millisecondsSinceEpoch}'.hashCode,
        title: '💰 Pengingat Tagihan',
        body: '${obligation.name} jatuh tempo: Rp ${obligation.monthlyAmount.toStringAsFixed(0)}',
        scheduledDate: DateTime.now().add(Duration(hours: hours)),
        payload: 'obligation:${obligation.id}:reminder',
      );

      LoggerService.debug('[ObligationReminderService] Snoozed reminder for ${obligation.name}');
    } catch (e) {
      LoggerService.error('Error snoozing reminder', error: e);
    }
  }
}

