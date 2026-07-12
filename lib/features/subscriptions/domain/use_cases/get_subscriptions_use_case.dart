import 'package:financial_app/models/subscription_model.dart';
import 'package:financial_app/features/subscriptions/domain/repositories/subscription_repository_interface.dart';

class GetSubscriptionsUseCase {
  final SubscriptionRepositoryInterface _r;
  GetSubscriptionsUseCase(this._r);
  Future<List<SubscriptionModel>> call({bool activeOnly = true}) =>
      _r.getSubscriptions(activeOnly: activeOnly);
}
