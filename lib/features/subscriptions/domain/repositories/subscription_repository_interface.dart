import 'package:financial_app/models/subscription_model.dart';

abstract class SubscriptionRepositoryInterface {
  Future<List<SubscriptionModel>> getSubscriptions({bool activeOnly = true});
  Future<SubscriptionModel> addSubscription(SubscriptionModel sub);
  Future<SubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> updates,
  );
  Future<void> deleteSubscription(String id);
  Future<Map<String, dynamic>> getSubscriptionSummary();
}
