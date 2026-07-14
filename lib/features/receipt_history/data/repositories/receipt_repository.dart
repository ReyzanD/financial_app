import 'package:financial_app/services/data/receipt_scan_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class ReceiptRepository {
  final ReceiptScanDataService _s;
  ReceiptRepository({ReceiptScanDataService? service})
    : _s = service ?? getIt<ReceiptScanDataService>();
  Future<List<dynamic>> getReceipts({int limit = 50, int offset = 0}) =>
      _s.getReceiptScans(limit: limit, offset: offset);
  Future<void> deleteReceipt(String id) => _s.deleteReceiptScan(id);
}
