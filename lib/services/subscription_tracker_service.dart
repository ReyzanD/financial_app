import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';
import 'package:financial_app/models/subscription_model.dart';

class SubscriptionTrackerService {
  final ObligationDataService _obligationData;

  SubscriptionTrackerService({ObligationDataService? obligationData})
    : _obligationData = obligationData ?? getIt<ObligationDataService>();

  Future<List<SubscriptionModel>> getSubscriptions({
    bool activeOnly = true,
  }) async {
    return _obligationData.getSubscriptions(activeOnly: activeOnly);
  }

  Future<SubscriptionModel> addSubscription(
    SubscriptionModel subscription,
  ) async {
    return _obligationData.addSubscription(subscription.toMap());
  }

  Future<SubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> updates,
  ) async {
    if (updates['next_renewal'] is DateTime) {
      updates['next_renewal'] =
          (updates['next_renewal'] as DateTime).toIso8601String();
    }
    return _obligationData.updateSubscription(id, updates);
  }

  Future<void> cancelSubscription(String id) async {
    await updateSubscription(id, {'is_active': false});
  }

  Future<void> renewSubscription(String id) async {
    final subs = await getSubscriptions(activeOnly: false);
    final sub = subs.firstWhere((s) => s.id == id);
    final nextRenewal = _calculateNextRenewal(sub);

    await updateSubscription(id, {'next_renewal': nextRenewal});
  }

  Future<Map<String, dynamic>> getSubscriptionSummary() async {
    return _obligationData.getSubscriptionSummary();
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
