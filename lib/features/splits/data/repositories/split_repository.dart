import 'package:financial_app/models/split_model.dart';
import 'package:financial_app/services/expense_split_service.dart';
import 'package:financial_app/features/splits/domain/repositories/split_repository_interface.dart';

class SplitRepository implements SplitRepositoryInterface {
  final ExpenseSplitService _s;
  SplitRepository({ExpenseSplitService? service}) : _s = service ?? ExpenseSplitService();

  @override Future<List<SplitModel>> getSplits({bool activeOnly = true}) => _s.getSplits(activeOnly: activeOnly);
  @override Future<SplitModel> createSplit(SplitModel split) => _s.createSplit(split);
  @override Future<void> deleteSplit(String id) => _s.deleteSplit(id);
  @override Future<Map<String, dynamic>> getSplitSummary() => _s.getSplitSummary();
}
