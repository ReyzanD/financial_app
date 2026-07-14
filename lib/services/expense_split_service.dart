import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/expense_split_data_service.dart';
import 'package:financial_app/models/feature_models.dart';

class ExpenseSplitService {
  final ExpenseSplitDataService _splitData;

  ExpenseSplitService({ExpenseSplitDataService? splitData})
    : _splitData = splitData ?? getIt<ExpenseSplitDataService>();

  Future<List<SplitModel>> getSplits({
    String? transactionId,
    bool activeOnly = true,
  }) async {
    return _splitData.getSplits(
      transactionId: transactionId,
      activeOnly: activeOnly,
    );
  }

  Future<SplitModel> createSplit(SplitModel split) async {
    return _splitData.addSplit(split.toMap());
  }

  Future<List<SplitModel>> createMultipleSplits(List<SplitModel> splits) async {
    final createdSplits = <SplitModel>[];
    for (var split in splits) {
      createdSplits.add(await _splitData.addSplit(split.toMap()));
    }
    return createdSplits;
  }

  Future<void> recordPayment(String splitId, double amount) async {
    final splits = await getSplits(activeOnly: false);
    final index = splits.indexWhere((s) => s.id == splitId);
    if (index == -1) throw Exception('Split not found');

    final split = splits[index];
    final newPaid = split.paidAmount + amount;
    final isSettled = newPaid >= split.amount;

    if (isSettled) {
      await settleSplit(splitId);
    }
  }

  Future<void> settleSplit(String splitId) async {
    await _splitData.settleSplit(splitId);
  }

  Future<Map<String, dynamic>> getSplitSummary() async {
    return _splitData.getSplitSummary();
  }

  Future<void> deleteSplit(String splitId) async {
    await _splitData.deleteSplit(splitId);
  }
}
