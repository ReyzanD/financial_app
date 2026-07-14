import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/notification_service.dart';
import 'package:financial_app/services/data/subscription_data_service.dart';
import 'package:financial_app/services/data/challenge_data_service.dart';
import 'package:financial_app/services/data/debt_data_service.dart';
import 'package:financial_app/services/data/expense_split_data_service.dart';
import 'package:financial_app/services/logger_service.dart';

class NotificationScheduler {
  final SubscriptionDataService _subscriptionData = getIt<SubscriptionDataService>();
  final ChallengeDataService _challengeData = getIt<ChallengeDataService>();
  final DebtDataService _debtData = getIt<DebtDataService>();
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
      final subscriptions = await _subscriptionData.getSubscriptions(
        activeOnly: true,
      );

      for (final sub in subscriptions) {
        if (sub.nextRenewal != null && sub.nextRenewal!.isAfter(DateTime.now())) {
          await _notifications.scheduleSubscriptionRenewal(
            name: sub.name,
            cost: sub.cost,
            renewalDate: sub.nextRenewal!,
            cycle: sub.cycle,
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
      final debts = await _debtData.getDebts();

      for (final debt in debts) {
        final name = debt.name;
        final monthlyPayment = debt.monthlyPayment;
        final dueDate = debt.dueDate;

        if (dueDate != null && monthlyPayment > 0 && dueDate.isAfter(DateTime.now())) {
          await _notifications.scheduleDebtPaymentReminder(
            name: name,
            amount: monthlyPayment,
            dueDate: dueDate,
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
