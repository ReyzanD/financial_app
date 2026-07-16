import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/split_model.dart';
import 'package:financial_app/services/expense_split_service.dart';

class SplitRepository {
  final ExpenseSplitService _s;
  SplitRepository({ExpenseSplitService? service}) : _s = service ?? getIt<ExpenseSplitService>();

  Future<List<SplitModel>> getSplits({bool activeOnly = true}) => _s.getSplits(activeOnly: activeOnly);
  Future<SplitModel> createSplit(SplitModel split) => _s.createSplit(split);
  Future<void> deleteSplit(String id) => _s.deleteSplit(id);
  Future<Map<String, dynamic>> getSplitSummary() => _s.getSplitSummary();
}
