import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/subscription_data_service.dart';
import 'package:financial_app/models/subscription_model.dart';

class SubscriptionTrackerService {
  final SubscriptionDataService _subscriptionData;

  SubscriptionTrackerService({SubscriptionDataService? subscriptionData})
    : _subscriptionData = subscriptionData ?? SubscriptionDataService();

  Future<List<SubscriptionModel>> getSubscriptions({
    bool activeOnly = true,
  }) async {
    try {
      final subsData = await _subscriptionData.getSubscriptions(
        activeOnly: activeOnly,
      );
      return subsData.map((s) => SubscriptionModel.fromMap(s)).toList();
    } catch (e) {
      LoggerService.error('Error getting subscriptions', error: e);
      rethrow;
    }
  }

  Future<SubscriptionModel> addSubscription(
    SubscriptionModel subscription,
  ) async {
    try {
      final result = await _subscriptionData.addSubscription(subscription.toMap());
      final created = SubscriptionModel.fromMap(
        result['subscription'] as Map<String, dynamic>,
      );
      LoggerService.success('Subscription added: ${created.name}');
      return created;
    } catch (e) {
      LoggerService.error('Error adding subscription', error: e);
      rethrow;
    }
  }

  Future<SubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      if (updates['next_renewal'] is DateTime) {
        updates['next_renewal'] =
            (updates['next_renewal'] as DateTime).toIso8601String();
      }
      final result = await _subscriptionData.updateSubscription(id, updates);
      final updated = SubscriptionModel.fromMap(
        result['subscription'] as Map<String, dynamic>,
      );
      LoggerService.success('Subscription updated: ${updated.name}');
      return updated;
    } catch (e) {
      LoggerService.error('Error updating subscription', error: e);
      rethrow;
    }
  }

  Future<void> cancelSubscription(String id) async {
    try {
      await updateSubscription(id, {'is_active': false});
      LoggerService.success('Subscription cancelled');
    } catch (e) {
      LoggerService.error('Error cancelling subscription', error: e);
      rethrow;
    }
  }

  Future<void> renewSubscription(String id) async {
    try {
      final subs = await getSubscriptions(activeOnly: false);
      final sub = subs.firstWhere((s) => s.id == id);
      final nextRenewal = _calculateNextRenewal(sub);

      await updateSubscription(id, {'next_renewal': nextRenewal});
      LoggerService.success('Subscription renewed: ${sub.name}');
    } catch (e) {
      LoggerService.error('Error renewing subscription', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSubscriptionSummary() async {
    try {
      return await _subscriptionData.getSubscriptionSummary();
    } catch (e) {
      LoggerService.error('Error getting subscription summary', error: e);
      rethrow;
    }
  }

  Future<double> calculateCostPerUse(String subscriptionId, int uses) async {
    final subs = await getSubscriptions(activeOnly: false);
    final sub = subs.firstWhere((s) => s.id == subscriptionId);
    return uses > 0 ? sub.monthlyCost / uses : sub.monthlyCost;
  }

  DateTime? _calculateNextRenewal(SubscriptionModel sub) {
    DateTime date = sub.nextRenewal ?? sub.startDate;
    final now = DateTime.now();
    while (date.isBefore(now)) {
      switch (sub.cycle) {
        case 'weekly':
          date = date.add(const Duration(days: 7));
          break;
        case 'monthly':
          date = DateTime(date.year, date.month + 1, date.day);
          break;
        case 'yearly':
          date = DateTime(date.year + 1, date.month, date.day);
          break;
      }
    }
    return date.isAfter(now) ? date : null;
  }
}
