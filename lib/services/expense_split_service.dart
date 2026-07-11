import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/expense_split_data_service.dart';
import 'package:financial_app/models/feature_models.dart';

class ExpenseSplitService {
  final ExpenseSplitDataService _splitData;

  ExpenseSplitService({ExpenseSplitDataService? splitData})
    : _splitData = splitData ?? ExpenseSplitDataService();

  Future<List<SplitModel>> getSplits({
    String? transactionId,
    bool activeOnly = true,
  }) async {
    try {
      final splitsData = await _splitData.getSplits(
        transactionId: transactionId,
        activeOnly: activeOnly,
      );
      return splitsData.map((s) => SplitModel.fromMap(s)).toList();
    } catch (e) {
      LoggerService.error('Error getting splits', error: e);
      rethrow;
    }
  }

  Future<SplitModel> createSplit(SplitModel split) async {
    try {
      final result = await _splitData.addSplit(split.toMap());
      final created = SplitModel.fromMap(
        result['split'] as Map<String, dynamic>,
      );
      LoggerService.success('Split created for ${created.participantName}');
      return created;
    } catch (e) {
      LoggerService.error('Error creating split', error: e);
      rethrow;
    }
  }

  Future<List<SplitModel>> createMultipleSplits(List<SplitModel> splits) async {
    try {
      final createdSplits = <SplitModel>[];
      for (var split in splits) {
        final result = await _splitData.addSplit(split.toMap());
        createdSplits.add(
          SplitModel.fromMap(result['split'] as Map<String, dynamic>),
        );
      }
      LoggerService.success('${splits.length} splits created');
      return createdSplits;
    } catch (e) {
      LoggerService.error('Error creating splits', error: e);
      rethrow;
    }
  }

  Future<void> recordPayment(String splitId, double amount) async {
    try {
      final splits = await getSplits(activeOnly: false);
      final index = splits.indexWhere((s) => s.id == splitId);
      if (index == -1) throw Exception('Split not found');

      final split = splits[index];
      final newPaid = split.paidAmount + amount;
      final isSettled = newPaid >= split.amount;

      if (isSettled) {
        await settleSplit(splitId);
      }
      LoggerService.success('Payment recorded for split: $amount');
    } catch (e) {
      LoggerService.error('Error recording split payment', error: e);
      rethrow;
    }
  }

  Future<void> settleSplit(String splitId) async {
    try {
      await _splitData.settleSplit(splitId);
      LoggerService.success('Split settled');
    } catch (e) {
      LoggerService.error('Error settling split', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSplitSummary() async {
    try {
      return await _splitData.getSplitSummary();
    } catch (e) {
      LoggerService.error('Error getting split summary', error: e);
      return {};
    }
  }

  Future<void> deleteSplit(String splitId) async {
    try {
      await _splitData.deleteSplit(splitId);
      LoggerService.success('Split deleted');
    } catch (e) {
      LoggerService.error('Error deleting split', error: e);
      rethrow;
    }
  }
}
