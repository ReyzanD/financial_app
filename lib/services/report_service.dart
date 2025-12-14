import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:financial_app/models/transaction_model.dart';

class ReportService {
  /// Generate PDF report for monthly or yearly transactions
  Future<File> generatePdfReport({
    required List<TransactionModel> transactions,
    required String periodType, // 'monthly' or 'yearly'
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Calculate summary
    final totalIncome = transactions
        .where((t) => t.type.toLowerCase() == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type.toLowerCase() == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final netBalance = totalIncome - totalExpense;

    // Group by category for expense breakdown
    final Map<String, double> categoryExpenses = {};
    for (var transaction in transactions) {
      if (transaction.type.toLowerCase() == 'expense') {
        final category = transaction.categoryName;
        categoryExpenses[category] =
            (categoryExpenses[category] ?? 0) + transaction.amount;
      }
    }

    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Build PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Laporan Keuangan',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        periodType == 'monthly'
                            ? 'Laporan Bulanan'
                            : 'Laporan Tahunan',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    dateFormat.format(DateTime.now()),
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Period Information
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Periode: ',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Section
            pw.Text(
              'Ringkasan',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildSummaryBox(
                    'Total Pemasukan',
                    totalIncome,
                    PdfColors.green,
                    currencyFormat,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _buildSummaryBox(
                    'Total Pengeluaran',
                    totalExpense,
                    PdfColors.red,
                    currencyFormat,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _buildSummaryBox(
                    'Saldo Bersih',
                    netBalance,
                    netBalance >= 0 ? PdfColors.blue : PdfColors.orange,
                    currencyFormat,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Category Breakdown
            if (sortedCategories.isNotEmpty) ...[
              pw.Text(
                'Pengeluaran per Kategori',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Kategori',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Jumlah',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Persentase',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...sortedCategories.take(10).map((entry) {
                    final percentage =
                        (entry.value / totalExpense * 100).toStringAsFixed(1);
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            entry.key,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            currencyFormat.format(entry.value),
                            style: const pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '$percentage%',
                            style: const pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 30),
            ],

            // Transaction List
            pw.Text(
              'Daftar Transaksi',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _buildTableCell('Tanggal', isHeader: true),
                    _buildTableCell('Kategori', isHeader: true),
                    _buildTableCell('Tipe', isHeader: true),
                    _buildTableCell('Metode', isHeader: true),
                    _buildTableCell('Jumlah', isHeader: true, alignRight: true),
                  ],
                ),
                // Transactions (limit to 50 for PDF size)
                ...transactions.take(50).map((transaction) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                        DateFormat('dd/MM/yyyy', 'id_ID')
                            .format(transaction.transactionDate),
                      ),
                      _buildTableCell(transaction.categoryName),
                      _buildTableCell(
                        transaction.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                      ),
                      _buildTableCell(
                        transaction.paymentMethod == 'cash'
                            ? 'Tunai'
                            : transaction.paymentMethod == 'card'
                                ? 'Kartu'
                                : transaction.paymentMethod,
                      ),
                      _buildTableCell(
                        '${transaction.type == 'income' ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                        alignRight: true,
                        color: transaction.type == 'income'
                            ? PdfColors.green
                            : PdfColors.red,
                      ),
                    ],
                  );
                }),
              ],
            ),

            // Footer
            if (transactions.length > 50)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 12),
                child: pw.Text(
                  'Catatan: Hanya menampilkan 50 transaksi pertama. Total transaksi: ${transactions.length}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final periodLabel = periodType == 'monthly'
        ? '${DateFormat('MMM_yyyy', 'id_ID').format(startDate)}'
        : '${startDate.year}';
    final filename = 'laporan_keuangan_${periodLabel}_$timestamp.pdf';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildSummaryBox(
    String label,
    double amount,
    PdfColor color,
    NumberFormat currencyFormat,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            currencyFormat.format(amount),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool alignRight = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  /// Generate CSV export with filters
  Future<File> generateCsvExport({
    required List<TransactionModel> transactions,
    String? typeFilter, // 'income' or 'expense'
    String? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Apply filters
    List<TransactionModel> filtered = List.from(transactions);

    if (typeFilter != null && typeFilter != 'all') {
      filtered = filtered
          .where((t) => t.type.toLowerCase() == typeFilter.toLowerCase())
          .toList();
    }

    if (categoryFilter != null && categoryFilter != 'all') {
      filtered = filtered
          .where((t) => t.categoryName == categoryFilter)
          .toList();
    }

    if (startDate != null) {
      filtered = filtered
          .where((t) => t.transactionDate.isAfter(startDate.subtract(
                const Duration(days: 1),
              )) ||
              t.transactionDate.isAtSameMomentAs(startDate))
          .toList();
    }

    if (endDate != null) {
      filtered = filtered
          .where((t) => t.transactionDate.isBefore(endDate.add(
                const Duration(days: 1),
              )))
          .toList();
    }

    // Sort by date descending
    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    // Create CSV data
    final List<List<dynamic>> csvData = [
      // Header
      [
        'Tanggal',
        'Waktu',
        'Tipe',
        'Kategori',
        'Deskripsi',
        'Jumlah',
        'Metode Pembayaran',
        'Lokasi',
      ],
      // Data
      ...filtered.map((transaction) {
        return [
          DateFormat('yyyy-MM-dd', 'id_ID').format(transaction.transactionDate),
          DateFormat('HH:mm:ss', 'id_ID').format(transaction.transactionDate),
          transaction.type == 'income' ? 'Pemasukan' : 'Pengeluaran',
          transaction.categoryName,
          transaction.description,
          transaction.amount.toStringAsFixed(2),
          transaction.paymentMethod == 'cash'
              ? 'Tunai'
              : transaction.paymentMethod == 'card'
                  ? 'Kartu'
                  : transaction.paymentMethod,
          transaction.locationData?['address'] ?? transaction.locationData?['place_name'] ?? '',
        ];
      }),
    ];

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'export_transaksi_$timestamp.csv';
    final file = File('${directory.path}/$filename');
    await file.writeAsString(csvString);

    return file;
  }
}


