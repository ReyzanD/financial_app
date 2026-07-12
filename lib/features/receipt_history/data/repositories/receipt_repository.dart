import 'package:financial_app/services/data/receipt_scan_data_service.dart';
import 'package:financial_app/features/receipt_history/domain/repositories/receipt_repository_interface.dart';

class ReceiptRepository implements ReceiptRepositoryInterface {
  final ReceiptScanDataService _s;
  ReceiptRepository({ReceiptScanDataService? service})
    : _s = service ?? ReceiptScanDataService();
  @override
  Future<List<dynamic>> getReceipts({int limit = 50, int offset = 0}) =>
      _s.getReceiptScans(limit: limit, offset: offset);
  @override
  Future<void> deleteReceipt(String id) => _s.deleteReceiptScan(id);
}
