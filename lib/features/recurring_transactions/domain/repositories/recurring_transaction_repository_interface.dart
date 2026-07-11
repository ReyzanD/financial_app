abstract class RecurringTransactionRepositoryInterface {
  Future<List<Map<String, dynamic>>> getRecurringTransactions({bool activeOnly = true});
  Future<void> pauseRecurringTransaction(String id);
  Future<void> resumeRecurringTransaction(String id);
  Future<void> deleteRecurringTransaction(String id);
}
