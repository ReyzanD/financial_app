import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/receipt_history/presentation/controllers/receipt_controller.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/receipt_scanning_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  State<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  bool _isScanning = false;
  final ReceiptScanningService _receiptScanningService =
      ReceiptScanningService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.receipt_history ?? 'Riwayat Struk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ReceiptController>().refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: Consumer<ReceiptController>(
              builder: (context, ctrl, _) {
                if (ctrl.isLoading)
                  return const Center(child: CircularProgressIndicator());
                if (ctrl.error != null) return _buildErrorState(ctrl);
                if (ctrl.receipts.isEmpty) return _buildEmptyState();
                return _buildReceiptsList(ctrl);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ReceiptController ctrl) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              l10n?.failed_to_load_data ?? 'Gagal Memuat Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ctrl.error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: ctrl.refresh,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.no_receipts_yet ?? 'Belum Ada Struk',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan struk untuk mulai melacak pengeluaran Anda',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _scanReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
              ),
              child: Text(
                l10n?.scan_receipt ?? 'Scan Struk',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanReceipt() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    try {
      final imageFile = await _receiptScanningService.pickImage(
        fromCamera: true,
      );
      if (imageFile == null) {
        if (mounted) setState(() => _isScanning = false);
        return;
      }

      final scanResult = await _receiptScanningService.scanReceipt(imageFile);
      if (scanResult != null && mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          AppLocalizations.of(context)?.receipt_scanned ??
              'Struk berhasil dipindai',
        );
        await context.read<ReceiptController>().refresh();
      } else if (mounted) {
        ErrorHandlerService.showWarningSnackbar(
          context,
          AppLocalizations.of(context)?.cannot_scan_receipt_try_again ??
              'Tidak dapat memindai struk. Coba lagi.',
        );
      }
    } catch (e) {
      if (mounted)
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
        );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Widget _buildReceiptsList(ReceiptController ctrl) {
    final receipts = List<Map<String, dynamic>>.from(ctrl.receipts);
    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: receipts.length,
      itemBuilder: (context, index) => _buildReceiptCard(receipts[index], ctrl),
    );
  }

  Widget _buildReceiptCard(
    Map<String, dynamic> receipt,
    ReceiptController ctrl,
  ) {
    final merchant = receipt['merchant_232143'] as String? ?? 'Tidak Diketahui';
    final total = (receipt['total_amount_232143'] as num?)?.toDouble() ?? 0.0;
    final dateStr = receipt['receipt_date_232143'] as String?;
    final imagePath = receipt['image_path_232143'] as String?;
    final isProcessed = receipt['is_processed_232143'] == 1;
    final receiptId = receipt['receipt_id_232143'] as String;
    final createdAt = receipt['created_at_232143'] as String?;

    DateTime? date;
    if (dateStr != null) {
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {}
    }
    if (date == null && createdAt != null) {
      try {
        date = DateTime.parse(createdAt);
      } catch (_) {}
    }

    return Dismissible(
      key: Key(receiptId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red[400],
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss:
          (_) => showDialog<bool>(
            context: context,
            builder: (c) {
              final l10n = AppLocalizations.of(c);
              return AlertDialog(
                title: Text(l10n?.delete_receipt_confirm ?? 'Hapus Struk?'),
                content: const Text('Struk ini akan dihapus secara permanen.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(l10n?.cancel ?? 'Batal'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(l10n?.delete ?? 'Hapus'),
                  ),
                ],
              );
            },
          ),
      onDismissed: (_) async {
        await ctrl.deleteReceipt(receiptId);
        if (imagePath != null) {
          try {
            final f = File(imagePath);
            if (await f.exists()) await f.delete();
          } catch (_) {}
        }
        if (mounted)
          ErrorHandlerService.showSuccessSnackbar(
            context,
            AppLocalizations.of(context)?.receipt_deleted ?? 'Struk dihapus',
          );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showReceiptDetail(receipt, ctrl),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacing4),
            child: Row(
              children: [
                _buildReceiptThumbnail(imagePath),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchant,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatRupiah(total.toInt()),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date != null
                                ? '${date.day}/${date.month}/${date.year}'
                                : 'Tanggal tidak diketahui',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isProcessed
                                      ? Colors.green[50]
                                      : Colors.orange[50],
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusMedium,
                              ),
                            ),
                            child: Text(
                              isProcessed
                                  ? (AppLocalizations.of(context)?.processed ??
                                      'Diproses')
                                  : (AppLocalizations.of(
                                        context,
                                      )?.not_processed ??
                                      'Belum Diproses'),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    isProcessed
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isProcessed ? Iconsax.edit : Iconsax.add_circle,
                    color:
                        isProcessed
                            ? DesignTokens.textSecondaryDark
                            : DesignTokens.primaryColor,
                    size: 24,
                  ),
                  onPressed: () => _createTransactionFromReceipt(receipt),
                  tooltip:
                      isProcessed
                          ? (AppLocalizations.of(
                                context,
                              )?.create_transaction_again ??
                              'Buat transaksi lagi')
                          : (AppLocalizations.of(context)?.create_transaction ??
                              'Buat transaksi'),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptThumbnail(String? imagePath) {
    if (imagePath != null && File(imagePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
          ),
        ),
      );
    }
    return _buildDefaultThumbnail();
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.receipt_long, color: Colors.grey[500], size: 30),
    );
  }

  void _createTransactionFromReceipt(Map<String, dynamic> receipt) async {
    final merchant = receipt['merchant_232143'] as String? ?? '';
    final total = (receipt['total_amount_232143'] as num?)?.toDouble() ?? 0.0;
    final dateStr = receipt['receipt_date_232143'] as String?;
    DateTime? receiptDate;
    if (dateStr != null) {
      try {
        receiptDate = DateTime.parse(dateStr);
      } catch (_) {}
    }
    receiptDate ??= DateTime.now();
    final description = merchant.isNotEmpty ? merchant : 'Transaksi dari struk';
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddTransactionScreen(
              transaction: {
                'amount': total,
                'description': description,
                'type': 'expense',
                'date': receiptDate!.toIso8601String(),
              },
            ),
      ),
    );
    if (result == true && mounted) {
      receipt['is_processed_232143'] = 1;
      ErrorHandlerService.showSuccessSnackbar(
        context,
        '${AppLocalizations.of(context)?.transaction_created_from_receipt ?? 'Transaksi berhasil dibuat dari struk:'} $merchant',
      );
    }
  }

  void _showReceiptDetail(
    Map<String, dynamic> receipt,
    ReceiptController ctrl,
  ) {
    final merchant = receipt['merchant_232143'] as String? ?? 'Tidak Diketahui';
    final total = (receipt['total_amount_232143'] as num?)?.toDouble() ?? 0.0;
    final dateStr = receipt['receipt_date_232143'] as String?;
    final imagePath = receipt['image_path_232143'] as String?;
    final items = receipt['items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (c) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (_, scrollController) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (imagePath != null && File(imagePath).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusMedium,
                          ),
                          child: Image.file(
                            File(imagePath),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        merchant,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.formatRupiah(total.toInt()),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (dateStr != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tanggal: $dateStr',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Item:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...items.map<Widget>(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item['description']?.toString() ?? '',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatRupiah(
                                    (item['amount'] as num).toInt(),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text(
                        'Detail OCR',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          receipt['raw_text_232143'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(c);
                            _createTransactionFromReceipt(receipt);
                          },
                          icon: const Icon(Iconsax.add),
                          label: Text(
                            receipt['is_processed_232143'] == 1
                                ? (AppLocalizations.of(
                                      c,
                                    )?.create_transaction_again ??
                                    'Buat Transaksi Lagi')
                                : (AppLocalizations.of(
                                      c,
                                    )?.create_transaction_from_receipt ??
                                    'Buat Transaksi dari Struk'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
