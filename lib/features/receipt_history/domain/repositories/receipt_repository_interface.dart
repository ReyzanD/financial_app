abstract class ReceiptRepositoryInterface {
  Future<List<dynamic>> getReceipts({int limit = 50, int offset = 0});
  Future<void> deleteReceipt(String id);
}
