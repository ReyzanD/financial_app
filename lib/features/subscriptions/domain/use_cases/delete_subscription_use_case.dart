import 'package:financial_app/features/subscriptions/domain/repositories/subscription_repository_interface.dart';

class DeleteSubscriptionUseCase {
  final SubscriptionRepositoryInterface _r;
  DeleteSubscriptionUseCase(this._r);
  Future<void> call(String id) => _r.deleteSubscription(id);
}
