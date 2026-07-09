import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/local_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/Screen/add_transaction_screen.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  State<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  final LocalDataService _localData = LocalDataService();
  List<Map<String, dynamic>> _receipts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final receipts = await _localData.getReceiptScans();
      setState(() {
        _receipts = receipts;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading receipts', error: e);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Struk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceipts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildErrorState()
                    : _receipts.isEmpty
                    ? _buildEmptyState()
                    : _buildReceiptsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Data',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadReceipts,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              'Belum Ada Struk',
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
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _receipts.length,
      itemBuilder: (context, index) {
        final receipt = _receipts[index];
        return _buildReceiptCard(receipt);
      },
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
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
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Hapus Struk?'),
                content: const Text('Struk ini akan dihapus secara permanen.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
        );
      },
      onDismissed: (direction) async {
        await _localData.deleteReceiptScan(receiptId);

        if (imagePath != null) {
          try {
            final file = File(imagePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            LoggerService.warning('Error deleting receipt image', error: e);
          }
        }

        setState(() {
          _receipts.removeWhere((r) => r['receipt_id_232143'] == receiptId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Struk dihapus'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showReceiptDetail(receipt),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                          if (isProcessed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Diproses',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Belum Diproses',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
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
                      isProcessed ? 'Buat transaksi lagi' : 'Buat transaksi',
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
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultThumbnail();
            },
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
            (context) => AddTransactionScreen(
              transaction: {
                'amount': total,
                'description': description,
                'type': 'expense',
                'date': receiptDate!.toIso8601String(),
              },
            ),
      ),
    );

    if (result == true) {
      setState(() {
        receipt['is_processed_232143'] = 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaksi berhasil dibuat dari struk: $merchant'),
            backgroundColor: DesignTokens.successColor,
          ),
        );
      }
    }
  }

  void _showReceiptDetail(Map<String, dynamic> receipt) {
    final merchant = receipt['merchant_232143'] as String? ?? 'Tidak Diketahui';
    final total = (receipt['total_amount_232143'] as num?)?.toDouble() ?? 0.0;
    final dateStr = receipt['receipt_date_232143'] as String?;
    final imagePath = receipt['image_path_232143'] as String?;
    final items = receipt['items'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => Padding(
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
                          borderRadius: BorderRadius.circular(12),
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
                        'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                                  'Rp ${(item['amount'] as num).toDouble().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
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
                            Navigator.pop(context);
                            _createTransactionFromReceipt(receipt);
                          },
                          icon: const Icon(Iconsax.add),
                          label: Text(
                            receipt['is_processed_232143'] == 1
                                ? 'Buat Transaksi Lagi'
                                : 'Buat Transaksi dari Struk',
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
