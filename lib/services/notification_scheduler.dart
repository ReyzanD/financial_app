import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';
import 'package:financial_app/services/data/challenge_data_service.dart';
import 'package:financial_app/services/data/expense_split_data_service.dart';
import 'package:financial_app/services/logger_service.dart';

class NotificationScheduler {
  final ObligationDataService _obligationData = getIt<ObligationDataService>();
  final ChallengeDataService _challengeData = getIt<ChallengeDataService>();
  final ExpenseSplitDataService _splitData = getIt<ExpenseSplitDataService>();
  final NotificationService _notifications = getIt<NotificationService>();

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
      final subscriptions = await _obligationData.getObligations(
        type: 'subscription',
      );

      for (final sub in subscriptions) {
        if (sub.dueDate.isAfter(DateTime.now())) {
          await _notifications.scheduleSubscriptionRenewal(
            name: sub.name,
            cost: sub.monthlyAmount,
            renewalDate: sub.dueDate,
            cycle: sub.subscriptionCycle ?? 'monthly',
          );
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
        if (challenge.endDate.isAfter(DateTime.now())) {
          await _notifications.scheduleChallengeReminder(
            name: challenge.name,
            endDate: challenge.endDate,
            progress: challenge.currentProgress,
            target: challenge.target,
          );

          if (challenge.isCompleted) {
            await _notifications.sendChallengeCompleted(
              name: challenge.name,
              progress: challenge.currentProgress,
              target: challenge.target,
            );
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error scheduling challenge notifications', error: e);
    }
  }

  Future<void> scheduleDebtNotifications() async {
    try {
      final debts = await _obligationData.getObligations(type: 'debt');

      for (final debt in debts) {
        if (debt.dueDate.isAfter(DateTime.now())) {
          await _notifications.scheduleDebtPaymentReminder(
            name: debt.name,
            amount: debt.monthlyAmount,
            dueDate: debt.dueDate,
          );
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
        if (!split.isSettled) {
          final daysSinceCreated =
              DateTime.now().difference(split.createdAt).inDays;

          if (daysSinceCreated > 7) {
            await _notifications.sendSplitPaymentReminder(
              participantName: split.participantName,
              amount: split.amount,
              description: split.notes ?? 'Split bill',
            );
          }
        }
      }
    } catch (e) {
      LoggerService.error('Error scheduling split notifications', error: e);
    }
  }
}
