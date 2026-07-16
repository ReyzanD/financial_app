import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/report_service.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/features/report/presentation/controllers/report_controller.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'dart:io';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/date_picker_helper.dart';

class ReportScreen extends StatefulWidget {
  /// When [embedded] is true (e.g. inside AnalyticsHubScreen),
  /// the own AppBar is suppressed (hub's AppBar handles navigation).
  final bool embedded;

  const ReportScreen({super.key, this.embedded = false});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _localeInitialized = false;
  String _selectedPeriodType = 'monthly';
  DateTime? _selectedMonth;
  int? _selectedYear;
  String _selectedFormat = 'pdf';
  String? _selectedTypeFilter;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedYear = now.year;
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    if (mounted) setState(() => _localeInitialized = true);
  }

  Future<void> _generateReport() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedMonth == null && _selectedYear == null) {
      ErrorHandlerService.showWarningSnackbar(context, AppLocalizations.of(context)!.please_select_period_first);
      return;
    }

    final ctrl = context.read<ReportController>();

    DateTime startDate;
    DateTime endDate;

    if (_selectedPeriodType == 'monthly') {
      if (_selectedMonth == null) {
        ErrorHandlerService.showWarningSnackbar(context, AppLocalizations.of(context)!.please_select_month);
        return;
      }
      startDate = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1);
      endDate = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 0, 23, 59, 59);
    } else {
      if (_selectedYear == null) {
        ErrorHandlerService.showWarningSnackbar(context, AppLocalizations.of(context)!.please_select_year);
        return;
      }
      startDate = DateTime(_selectedYear!, 1, 1);
      endDate = DateTime(_selectedYear!, 12, 31, 23, 59, 59);
    }

    await ctrl.generate(start: startDate, end: endDate, type: _selectedTypeFilter ?? 'all');
    if (!mounted) return;

    final data = ctrl.reportData;
    if (data.isEmpty) return;

    final transactions = List<dynamic>.from(data['transactions'] ?? []);
    if (transactions.isEmpty) {
      ErrorHandlerService.showWarningSnackbar(context, AppLocalizations.of(context)!.no_transactions_for_period);
      return;
    }

    try {
      final reportService = ReportService();
      File file;
      if (_selectedFormat == 'pdf') {
        file = await reportService.generatePdfReport(
          transactions: transactions.map((j) => TransactionModel.fromJson(j as Map<String, dynamic>)).toList(),
          periodType: _selectedPeriodType,
          startDate: startDate,
          endDate: endDate,
        );
        await _showPdfPreview(file);
      } else {
        file = await reportService.generateCsvExport(
          transactions: transactions.map((j) => TransactionModel.fromJson(j as Map<String, dynamic>)).toList(),
          typeFilter: _selectedTypeFilter,
          categoryFilter: _selectedCategoryFilter,
          startDate: startDate,
          endDate: endDate,
        );
        await _shareFile(file);
      }
      if (mounted)
        ErrorHandlerService.showSuccessSnackbar(
          context,
          l10n?.report_created_successfully ?? 'Report berhasil dibuat!',
        );
    } catch (e) {
      LoggerService.error('Error generating report', error: e);
      if (mounted)
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _generateReport,
        );
    }
  }

  Future<void> _showPdfPreview(File file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (c) {
        final l10n = AppLocalizations.of(c);
        return AlertDialog(
          backgroundColor: DesignTokens.surfaceDark,
          title: Text(
            l10n?.report_created_successfully ?? 'Laporan Berhasil Dibuat',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(AppLocalizations.of(c)!.select_action, style: GoogleFonts.poppins(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                _shareFile(file);
              },
              child: Text(l10n?.share ?? 'Bagikan', style: GoogleFonts.poppins(color: DesignTokens.primaryColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(c);
                await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
              },
              child: Text('Preview & Print', style: GoogleFonts.poppins(color: DesignTokens.primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareFile(File file) async {
    final l10n = AppLocalizations.of(context);
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${_selectedFormat == 'pdf' ? (l10n?.financial_report ?? 'Laporan Keuangan') : (l10n?.export_transaction ?? 'Export Transaksi')} - ${_getPeriodLabel()}',
      );
    } catch (e) {
      LoggerService.error('Error sharing file', error: e);
      if (mounted) ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
    }
  }

  String _getPeriodLabel() {
    final l10n = AppLocalizations.of(context);
    if (_selectedPeriodType == 'monthly' && _selectedMonth != null)
      return DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth!);
    if (_selectedPeriodType == 'yearly' && _selectedYear != null) return _selectedYear.toString();
    return l10n?.period ?? 'Periode';
  }

  Future<void> _selectMonth() async {
    final now = DateTime.now();
    final picked = await DatePickerHelper.showDarkDatePicker(
      context: context,
      initialDate: _selectedMonth ?? now,
      firstDate: DateTime(now.year - 5, 1),
      lastDate: DateTime(now.year, now.month),
      initialDatePickerMode: DatePickerMode.year,
      helpText: AppLocalizations.of(context)?.select_month ?? 'Pilih Bulan',
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && mounted) setState(() => _selectedMonth = DateTime(picked.year, picked.month));
  }

  Future<void> _selectYear() async {
    final now = DateTime.now();
    final picked = await showDialog<int>(
      context: context,
      builder:
          (c) => AlertDialog(
            backgroundColor: DesignTokens.surfaceDark,
            title: Text(
              AppLocalizations.of(c)!.select_year,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                itemBuilder: (_, index) {
                  final year = now.year - index;
                  return ListTile(
                    title: Text(year.toString(), style: GoogleFonts.poppins(color: Colors.white)),
                    onTap: () => Navigator.pop(c, year),
                  );
                },
              ),
            ),
          ),
    );
    if (picked != null && mounted) setState(() => _selectedYear = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_localeInitialized) {
      return Scaffold(
        backgroundColor: DesignTokens.backgroundDark,
        appBar:
            widget.embedded
                ? null
                : AppBar(
                  backgroundColor: DesignTokens.backgroundDark,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                    tooltip: l10n?.back ?? 'Kembali',
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    l10n?.create_report ?? 'Buat Laporan',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
        body: const Column(
          children: [
            OfflineIndicator(),
            Expanded(child: Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar:
          widget.embedded
              ? null
              : AppBar(
                backgroundColor: DesignTokens.backgroundDark,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                  tooltip: l10n?.back ?? 'Kembali',
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  l10n?.create_report ?? 'Buat Laporan',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacing4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(l10n?.period_type ?? 'Jenis Periode'),
                  const SizedBox(height: DesignTokens.spacing3),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPeriodTypeButton(
                          l10n?.monthly ?? 'Bulanan',
                          'monthly',
                          Icons.calendar_month_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPeriodTypeButton(
                          l10n?.yearly ?? 'Tahunan',
                          'yearly',
                          Icons.calendar_today_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing6),
                  _buildSectionTitle(AppLocalizations.of(context)!.select_period),
                  const SizedBox(height: DesignTokens.spacing3),
                  if (_selectedPeriodType == 'monthly')
                    _buildDateSelector(
                      l10n?.month ?? 'Bulan',
                      _selectedMonth != null
                          ? DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth!)
                          : AppLocalizations.of(context)!.select_month,
                      _selectMonth,
                      Icons.calendar_month_rounded,
                    )
                  else
                    _buildDateSelector(
                      l10n?.year ?? 'Tahun',
                      _selectedYear?.toString() ?? AppLocalizations.of(context)!.select_year,
                      _selectYear,
                      Icons.calendar_today_rounded,
                    ),
                  const SizedBox(height: DesignTokens.spacing6),
                  _buildSectionTitle(l10n?.report_format ?? 'Format Report'),
                  const SizedBox(height: DesignTokens.spacing3),
                  Row(
                    children: [
                      Expanded(child: _buildFormatButton('PDF', 'pdf', Icons.picture_as_pdf_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFormatButton('CSV', 'csv', Icons.table_chart_rounded)),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing6),
                  if (_selectedFormat == 'csv') ...[
                    _buildSectionTitle(AppLocalizations.of(context)!.filter_optional),
                    const SizedBox(height: DesignTokens.spacing3),
                    _buildFilterDropdown(
                      l10n?.transaction_type ?? 'Tipe Transaksi',
                      _selectedTypeFilter,
                      [l10n?.all ?? 'Semua', l10n?.income ?? 'Pemasukan', l10n?.expense ?? 'Pengeluaran'],
                      ['all', 'income', 'expense'],
                      (v) => setState(() => _selectedTypeFilter = v == 'all' ? null : v),
                    ),
                    const SizedBox(height: DesignTokens.spacing3),
                  ],
                  const SizedBox(height: DesignTokens.spacing7),
                  Consumer<ReportController>(
                    builder:
                        (context, ctrl, _) => ElevatedButton(
                          onPressed: ctrl.isLoading ? null : _generateReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                            ),
                            elevation: 0,
                          ),
                          child:
                              ctrl.isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.description_rounded, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n?.create_report ?? 'Buat Laporan',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                  ),
                  const SizedBox(height: DesignTokens.spacing4),
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spacing4),
                    decoration: BoxDecoration(
                      color: DesignTokens.surfaceDark,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                      border: Border.all(color: DesignTokens.primaryColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: DesignTokens.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n?.information ?? 'Informasi',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spacing2),
                        Text(
                          _selectedFormat == 'pdf'
                              ? '• PDF report akan menampilkan summary, breakdown kategori, dan daftar transaksi\n• Anda dapat preview dan print langsung dari aplikasi\n• Report dapat dibagikan via email atau WhatsApp'
                              : '• CSV export berisi semua data transaksi dalam format spreadsheet\n• Dapat dibuka dengan Excel, Google Sheets, atau aplikasi spreadsheet lainnya\n• File dapat dibagikan via email atau WhatsApp',
                          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) =>
      Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600));

  Widget _buildPeriodTypeButton(String label, String value, IconData icon) {
    final isSelected = _selectedPeriodType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriodType = value),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.primaryColor.withValues(alpha: 0.2) : DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: isSelected ? DesignTokens.primaryColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? DesignTokens.primaryColor : Colors.grey[400], size: 32),
            const SizedBox(height: DesignTokens.spacing2),
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
      onTap: () => setState(() => _selectedFormat = value),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.primaryColor.withValues(alpha: 0.2) : DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: isSelected ? DesignTokens.primaryColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? DesignTokens.primaryColor : Colors.grey[400], size: 32),
            const SizedBox(height: DesignTokens.spacing2),
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

  Widget _buildDateSelector(String label, String value, VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacing4),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(color: DesignTokens.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: DesignTokens.primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: DesignTokens.spacing1),
                  Text(
                    value,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
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
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.primaryColor.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value ?? 'all',
          dropdownColor: DesignTokens.surfaceDark,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          onChanged: (v) => onChanged(v),
          items: List.generate(options.length, (i) => DropdownMenuItem(value: values[i], child: Text(options[i]))),
        ),
      ),
    );
  }
}
