import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/data/subscription_data_service.dart';
import 'package:financial_app/services/data/challenge_data_service.dart';
import 'package:financial_app/services/data/debt_data_service.dart';
import 'package:financial_app/services/data/expense_split_data_service.dart';
import 'package:financial_app/services/logger_service.dart';

class NotificationScheduler {
  final SubscriptionDataService _subscriptionData = SubscriptionDataService();
  final ChallengeDataService _challengeData = ChallengeDataService();
  final DebtDataService _debtData = DebtDataService();
  final ExpenseSplitDataService _splitData = ExpenseSplitDataService();
  final NotificationService _notifications = NotificationService();

  Future<void> scheduleAllNotifications() async {
    LoggerService.info('Scheduling all notifications...');

    await scheduleSubscriptionNotifications();
    await scheduleChallengeNotifications();
    await scheduleDebtNotifications();
    await scheduleSplitNotifications();

    LoggerService.info('All notifications scheduled');
  }

  Future<void> scheduleSubscriptionNotifications() async {
    try {
      final subscriptions = await _subscriptionData.getSubscriptions(
        activeOnly: true,
      );

      for (final sub in subscriptions) {
        final name = sub['name_232143']?.toString() ?? '';
        final cost = (sub['cost_232143'] as num?)?.toDouble() ?? 0.0;
        final cycle = sub['cycle_232143']?.toString() ?? 'monthly';
        final nextRenewalStr = sub['next_renewal_232143']?.toString();

        if (nextRenewalStr != null) {
          final nextRenewal = DateTime.tryParse(nextRenewalStr);
          if (nextRenewal != null && nextRenewal.isAfter(DateTime.now())) {
            await _notifications.scheduleSubscriptionRenewal(
              name: name,
              cost: cost,
              renewalDate: nextRenewal,
              cycle: cycle,
            );
          }
        }
      }
    } catch (e) {
      LoggerService.error(
        'Error scheduling subscription notifications',
        error: e,
      );
    }
  }

  Future<void> scheduleChallengeNotifications() async {
    try {
      final challenges = await _challengeData.getChallenges(activeOnly: true);

      for (final challenge in challenges) {
        final name = challenge['name_232143']?.toString() ?? '';
        final target =
            (challenge['target_amount_232143'] as num?)?.toDouble() ?? 0.0;
        final progress =
            (challenge['current_amount_232143'] as num?)?.toDouble() ?? 0.0;
        final endDateStr = challenge['end_date_232143']?.toString();

        if (endDateStr != null) {
          final endDate = DateTime.tryParse(endDateStr);
          if (endDate != null) {
            await _notifications.scheduleChallengeReminder(
              name: name,
              endDate: endDate,
              progress: progress,
              target: target,
            );

            if (progress >= target && target > 0) {
              await _notifications.sendChallengeCompleted(
                name: name,
                progress: progress,
                target: target,
              );
            }
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error scheduling challenge notifications', error: e);
    }
  }

  Future<void> scheduleDebtNotifications() async {
    try {
      final debts = await _debtData.getDebts();

      for (final debt in debts) {
        final name = debt['name_232143']?.toString() ?? '';
        final monthlyPayment =
            (debt['monthly_payment_232143'] as num?)?.toDouble() ?? 0.0;
        final dueDateStr = debt['due_date_232143']?.toString();

        if (dueDateStr != null && monthlyPayment > 0) {
          final dueDate = DateTime.tryParse(dueDateStr);
          if (dueDate != null && dueDate.isAfter(DateTime.now())) {
            await _notifications.scheduleDebtPaymentReminder(
              name: name,
              amount: monthlyPayment,
              dueDate: dueDate,
            );
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error scheduling debt notifications', error: e);
    }
  }

  Future<void> scheduleSplitNotifications() async {
    try {
      final splits = await _splitData.getSplits();

      for (final split in splits) {
        final isSettled = _parseBool(split['is_settled_232143']) ?? false;

        if (!isSettled) {
          final participantName =
              split['participant_name_232143']?.toString() ?? '';
          final amount = (split['amount_232143'] as num?)?.toDouble() ?? 0.0;
          final notes = split['notes_232143']?.toString() ?? 'Split bill';

          final createdAtStr = split['created_at_232143']?.toString();
          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            final daysSinceCreated =
                createdAt != null
                    ? DateTime.now().difference(createdAt).inDays
                    : 0;

            if (daysSinceCreated > 7) {
              await _notifications.sendSplitPaymentReminder(
                participantName: participantName,
                amount: amount,
                description: notes,
              );
            }
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error scheduling split notifications', error: e);
    }
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    return null;
  }
}
