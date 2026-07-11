import 'package:financial_app/models/split_model.dart';

abstract class SplitRepositoryInterface {
  Future<List<SplitModel>> getSplits({bool activeOnly = true});
  Future<SplitModel> createSplit(SplitModel split);
  Future<void> deleteSplit(String id);
  Future<Map<String, dynamic>> getSplitSummary();
}
