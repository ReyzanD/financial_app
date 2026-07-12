import 'package:financial_app/models/subscription_model.dart';
import 'package:financial_app/features/subscriptions/domain/repositories/subscription_repository_interface.dart';

class AddSubscriptionUseCase {
  final SubscriptionRepositoryInterface _r;
  AddSubscriptionUseCase(this._r);
  Future<SubscriptionModel> call(SubscriptionModel sub) =>
      _r.addSubscription(sub);
}
