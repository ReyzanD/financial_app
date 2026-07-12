import 'package:financial_app/models/subscription_model.dart';
import 'package:financial_app/services/subscription_tracker_service.dart';
import 'package:financial_app/features/subscriptions/domain/repositories/subscription_repository_interface.dart';

class SubscriptionRepository implements SubscriptionRepositoryInterface {
  final SubscriptionTrackerService _s;
  SubscriptionRepository({SubscriptionTrackerService? service})
    : _s = service ?? SubscriptionTrackerService();

  @override
  Future<List<SubscriptionModel>> getSubscriptions({bool activeOnly = true}) =>
      _s.getSubscriptions(activeOnly: activeOnly);
  @override
  Future<SubscriptionModel> addSubscription(SubscriptionModel sub) =>
      _s.addSubscription(sub);
  @override
  Future<SubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> updates,
  ) => _s.updateSubscription(id, updates);
  @override
  Future<void> deleteSubscription(String id) => _s.cancelSubscription(id);
  @override
  Future<Map<String, dynamic>> getSubscriptionSummary() =>
      _s.getSubscriptionSummary();
}
