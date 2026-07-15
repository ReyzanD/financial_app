import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';

class InsightsRepository {
  final TransactionDataService _transactionData;
  final GoalDataService _goalData;
  InsightsRepository({
    TransactionDataService? transactionData,
    GoalDataService? goalData,
  }) : _transactionData = transactionData ?? getIt<TransactionDataService>(),
       _goalData = goalData ?? getIt<GoalDataService>();

  Future<Map<String, dynamic>> getTransactions({int limit = 500}) =>
      _transactionData.getTransactions(limit: limit);

  Future<List<dynamic>> getGoals() => _goalData.getGoals();
}
