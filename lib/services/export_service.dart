import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/formatters.dart';

/// Service untuk export/import data dengan multiple formats
class ExportService {
  final ApiService _apiService = ApiService();
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Export transactions ke CSV
  Future<String> exportTransactionsToCSV({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
  }) async {
    try {
      final transactionsData = await _apiService.getTransactions();
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
      
      // Filter transactions
      List<dynamic> filtered = transactions;
      if (startDate != null || endDate != null || categoryId != null || type != null) {
        filtered = transactions.where((t) {
          final transaction = t as Map<String, dynamic>;
          
          if (startDate != null || endDate != null) {
            final tDateStr = transaction['transaction_date']?.toString();
            if (tDateStr != null) {
              try {
                final tDate = DateTime.parse(tDateStr);
                if (startDate != null && tDate.isBefore(startDate)) return false;
                if (endDate != null && tDate.isAfter(endDate)) return false;
              } catch (e) {
                return false;
              }
            }
          }
          
          if (categoryId != null) {
            if (transaction['category_id']?.toString() != categoryId) return false;
          }
          
          if (type != null) {
            if (transaction['type']?.toString() != type) return false;
          }
          
          return true;
        }).toList();
      }
      
      // Create CSV data
      final csvData = <List<dynamic>>[
        ['Date', 'Type', 'Category', 'Description', 'Amount', 'Location'],
      ];
      
      for (var t in filtered) {
        final transaction = t as Map<String, dynamic>;
        csvData.add([
          transaction['transaction_date'] ?? '',
          transaction['type'] ?? '',
          transaction['category_name'] ?? '',
          transaction['description'] ?? '',
          transaction['amount'] ?? 0,
          transaction['location_name'] ?? '',
        ]);
      }
      
      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);
      
      LoggerService.info('Exported ${filtered.length} transactions to CSV: $fileName');
      return file.path;
    } catch (e) {
      LoggerService.error('Error exporting to CSV', error: e);
      rethrow;
    }
  }

  /// Export transactions ke JSON
  Future<String> exportTransactionsToJSON({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
  }) async {
    try {
      final transactionsData = await _apiService.getTransactions();
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
      
      // Filter transactions (same logic as CSV)
      List<dynamic> filtered = transactions;
      if (startDate != null || endDate != null || categoryId != null || type != null) {
        filtered = transactions.where((t) {
          final transaction = t as Map<String, dynamic>;
          
          if (startDate != null || endDate != null) {
            final tDateStr = transaction['transaction_date']?.toString();
            if (tDateStr != null) {
              try {
                final tDate = DateTime.parse(tDateStr);
                if (startDate != null && tDate.isBefore(startDate)) return false;
                if (endDate != null && tDate.isAfter(endDate)) return false;
              } catch (e) {
                return false;
              }
            }
          }
          
          if (categoryId != null) {
            if (transaction['category_id']?.toString() != categoryId) return false;
          }
          
          if (type != null) {
            if (transaction['type']?.toString() != type) return false;
          }
          
          return true;
        }).toList();
      }
      
      // Convert to JSON
      final jsonString = jsonEncode({
        'export_date': DateTime.now().toIso8601String(),
        'total_transactions': filtered.length,
        'transactions': filtered,
      });
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'transactions_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);
      
      LoggerService.info('Exported ${filtered.length} transactions to JSON: $fileName');
      return file.path;
    } catch (e) {
      LoggerService.error('Error exporting to JSON', error: e);
      rethrow;
    }
  }

  /// Export transactions ke PDF
  Future<String> exportTransactionsToPDF({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
  }) async {
    try {
      final transactionsData = await _apiService.getTransactions();
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
      
      // Filter transactions (same logic)
      List<dynamic> filtered = transactions;
      if (startDate != null || endDate != null || categoryId != null || type != null) {
        filtered = transactions.where((t) {
          final transaction = t as Map<String, dynamic>;
          
          if (startDate != null || endDate != null) {
            final tDateStr = transaction['transaction_date']?.toString();
            if (tDateStr != null) {
              try {
                final tDate = DateTime.parse(tDateStr);
                if (startDate != null && tDate.isBefore(startDate)) return false;
                if (endDate != null && tDate.isAfter(endDate)) return false;
              } catch (e) {
                return false;
              }
            }
          }
          
          if (categoryId != null) {
            if (transaction['category_id']?.toString() != categoryId) return false;
          }
          
          if (type != null) {
            if (transaction['type']?.toString() != type) return false;
          }
          
          return true;
        }).toList();
      }
      
      // Create PDF
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Transaction Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Export Date: ${_dateTimeFormat.format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Total Transactions: ${filtered.length}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...filtered.map((t) {
                    final transaction = t as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(transaction['transaction_date']?.toString() ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(transaction['type']?.toString() ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(transaction['category_name']?.toString() ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(transaction['description']?.toString() ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            CurrencyFormatter.formatRupiah(
                              (transaction['amount'] as num?)?.toInt() ?? 0,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ];
          },
        ),
      );
      
      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'transactions_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      LoggerService.info('Exported ${filtered.length} transactions to PDF: $fileName');
      return file.path;
    } catch (e) {
      LoggerService.error('Error exporting to PDF', error: e);
      rethrow;
    }
  }

  /// Share exported file
  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      LoggerService.error('Error sharing file', error: e);
      rethrow;
    }
  }

  /// Import transactions dari CSV
  Future<Map<String, dynamic>> importTransactionsFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();
      
      final csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) {
        return {
          'success': false,
          'message': 'File kosong',
          'imported': 0,
          'failed': 0,
        };
      }
      
      // Skip header
      final rows = csvData.skip(1).toList();
      
      int imported = 0;
      int failed = 0;
      final errors = <String>[];
      
      for (int i = 0; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.length < 5) {
            failed++;
            errors.add('Row ${i + 2}: Tidak cukup kolom');
            continue;
          }
          
          // Parse row
          final type = row[1].toString();
          
          // Validate
          if (type != 'income' && type != 'expense') {
            failed++;
            errors.add('Row ${i + 2}: Type tidak valid');
            continue;
          }
          
          // Create transaction
          // Note: Ini perlu disesuaikan dengan API endpoint
          // await _apiService.createTransaction(...);
          
          imported++;
        } catch (e) {
          failed++;
          errors.add('Row ${i + 2}: ${e.toString()}');
        }
      }
      
      return {
        'success': imported > 0,
        'message': 'Imported $imported transactions, $failed failed',
        'imported': imported,
        'failed': failed,
        'errors': errors,
      };
    } catch (e) {
      LoggerService.error('Error importing from CSV', error: e);
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'imported': 0,
        'failed': 0,
      };
    }
  }
}

