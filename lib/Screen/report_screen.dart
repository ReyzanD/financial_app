import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:financial_app/services/report_service.dart';
import 'package:financial_app/services/api/transaction_api.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'dart:io';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  bool _isGenerating = false;
  bool _localeInitialized = false;
  String _selectedPeriodType = 'monthly'; // 'monthly' or 'yearly'
  DateTime? _selectedMonth;
  int? _selectedYear;
  String _selectedFormat = 'pdf'; // 'pdf' or 'csv'
  String? _selectedTypeFilter; // 'income', 'expense', or null for all
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedYear = now.year;
    // Initialize locale data for Indonesian
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_selectedMonth == null && _selectedYear == null) {
      _showError('Silakan pilih periode terlebih dahulu');
      return;
    }

    setState(() => _isGenerating = true);

    try {
      DateTime startDate;
      DateTime endDate;

      if (_selectedPeriodType == 'monthly') {
        if (_selectedMonth == null) {
          setState(() => _isGenerating = false);
          _showError('Silakan pilih bulan');
          return;
        }
        startDate = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
        endDate = DateTime(
          _selectedMonth!.year,
          _selectedMonth!.month + 1,
          0,
          23,
          59,
          59,
        );
      } else {
        if (_selectedYear == null) {
          setState(() => _isGenerating = false);
          _showError('Silakan pilih tahun');
          return;
        }
        startDate = DateTime(_selectedYear!, 1, 1);
        endDate = DateTime(_selectedYear!, 12, 31, 23, 59, 59);
      }

      // Fetch transactions
      final transactionsData = await TransactionApi.getTransactions(
        limit: 10000,
        type: _selectedTypeFilter,
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );

      final transactions =
          transactionsData
              .map((json) => TransactionModel.fromJson(json))
              .toList();

      if (transactions.isEmpty) {
        setState(() => _isGenerating = false);
        _showError('Tidak ada transaksi untuk periode yang dipilih');
        return;
      }

      File file;

      if (_selectedFormat == 'pdf') {
        // Generate PDF
        file = await _reportService.generatePdfReport(
          transactions: transactions,
          periodType: _selectedPeriodType,
          startDate: startDate,
          endDate: endDate,
        );

        // Show preview and share options
        await _showPdfPreview(file);
      } else {
        // Generate CSV
        file = await _reportService.generateCsvExport(
          transactions: transactions,
          typeFilter: _selectedTypeFilter,
          categoryFilter: _selectedCategoryFilter,
          startDate: startDate,
          endDate: endDate,
        );

        // Share CSV
        await _shareFile(file);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report berhasil dibuat!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error generating report: $e');
      _showError('Gagal membuat report: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _showPdfPreview(File file) async {
    final bytes = await file.readAsBytes();

    // Show preview dialog with print and share options
    if (!mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              'Laporan Berhasil Dibuat',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Pilih aksi yang ingin dilakukan:',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _shareFile(file);
                },
                child: Text(
                  'Bagikan',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => bytes,
                  );
                },
                child: Text(
                  'Preview & Print',
                  style: GoogleFonts.poppins(color: const Color(0xFF8B5FBF)),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            _selectedFormat == 'pdf'
                ? 'Laporan Keuangan - ${_getPeriodLabel()}'
                : 'Export Transaksi - ${_getPeriodLabel()}',
      );
    } catch (e) {
      print('Error sharing file: $e');
      _showError('Gagal membagikan file: $e');
    }
  }

  String _getPeriodLabel() {
    if (_selectedPeriodType == 'monthly' && _selectedMonth != null) {
      return DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth!);
    } else if (_selectedPeriodType == 'yearly' && _selectedYear != null) {
      return _selectedYear.toString();
    }
    return 'Periode';
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5, 1);
    final lastDate = DateTime(now.year, now.month);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pilih Bulan',
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  Future<void> _selectYear() async {
    final now = DateTime.now();
    final picked = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Pilih Tahun',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 10,
              itemBuilder: (context, index) {
                final year = now.year - index;
                return ListTile(
                  title: Text(
                    year.toString(),
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, year),
                );
              },
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedYear = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Buat Laporan',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buat Laporan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Type Selection
            _buildSectionTitle('Jenis Periode'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodTypeButton(
                    'Bulanan',
                    'monthly',
                    Icons.calendar_month_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPeriodTypeButton(
                    'Tahunan',
                    'yearly',
                    Icons.calendar_today_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Period Selection
            _buildSectionTitle('Pilih Periode'),
            const SizedBox(height: 12),
            if (_selectedPeriodType == 'monthly')
              _buildDateSelector(
                'Bulan',
                _selectedMonth != null
                    ? DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth!)
                    : 'Pilih Bulan',
                _selectMonth,
                Icons.calendar_month_rounded,
              )
            else
              _buildDateSelector(
                'Tahun',
                _selectedYear?.toString() ?? 'Pilih Tahun',
                _selectYear,
                Icons.calendar_today_rounded,
              ),
            const SizedBox(height: 24),

            // Format Selection
            _buildSectionTitle('Format Report'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFormatButton(
                    'PDF',
                    'pdf',
                    Icons.picture_as_pdf_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormatButton(
                    'CSV',
                    'csv',
                    Icons.table_chart_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Options (for CSV)
            if (_selectedFormat == 'csv') ...[
              _buildSectionTitle('Filter (Opsional)'),
              const SizedBox(height: 12),
              _buildFilterDropdown(
                'Tipe Transaksi',
                _selectedTypeFilter,
                ['Semua', 'Pemasukan', 'Pengeluaran'],
                ['all', 'income', 'expense'],
                (value) {
                  setState(() {
                    _selectedTypeFilter = value == 'all' ? null : value;
                  });
                },
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 32),

            // Generate Button
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5FBF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child:
                  _isGenerating
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.description_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Buat Laporan',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B5FBF).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: const Color(0xFF8B5FBF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFormat == 'pdf'
                        ? '• PDF report akan menampilkan summary, breakdown kategori, dan daftar transaksi\n• Anda dapat preview dan print langsung dari aplikasi\n• Report dapat dibagikan via email atau WhatsApp'
                        : '• CSV export berisi semua data transaksi dalam format spreadsheet\n• Dapat dibuka dengan Excel, Google Sheets, atau aplikasi spreadsheet lainnya\n• File dapat dibagikan via email atau WhatsApp',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPeriodTypeButton(String label, String value, IconData icon) {
    final isSelected = _selectedPeriodType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriodType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF8B5FBF).withOpacity(0.2)
                  : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF8B5FBF)
                    : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF8B5FBF) : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatButton(String label, String value, IconData icon) {
    final isSelected = _selectedFormat == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormat = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF8B5FBF).withOpacity(0.2)
                  : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? const Color(0xFF8B5FBF)
                    : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF8B5FBF) : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    String value,
    VoidCallback onTap,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B5FBF), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> options,
    List<String> values,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value ?? 'all',
          dropdownColor: const Color(0xFF1A1A1A),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
          ),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          onChanged: (newValue) => onChanged(newValue),
          items: List.generate(
            options.length,
            (index) => DropdownMenuItem(
              value: values[index],
              child: Text(options[index]),
            ),
          ),
        ),
      ),
    );
  }
}
