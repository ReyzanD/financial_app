import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/utils/formatters.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _recurringTransactions = [];
  bool _isLoading = true;
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadRecurringTransactions();
  }

  Future<void> _loadRecurringTransactions() async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.getRecurringTransactions(
        activeOnly: _showActiveOnly,
      );
      final transactions = List<Map<String, dynamic>>.from(data);

      setState(() {
        _recurringTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recurring transactions: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFrequencyText(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Harian';
      case 'weekly':
        return 'Mingguan';
      case 'monthly':
        return 'Bulanan';
      case 'yearly':
        return 'Tahunan';
      default:
        return frequency;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Colors.green;
      case 'expense':
        return Colors.red;
      case 'transfer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'income':
        return Iconsax.arrow_down_1;
      case 'expense':
        return Iconsax.arrow_up_3;
      case 'transfer':
        return Iconsax.repeat;
      default:
        return Iconsax.wallet_3;
    }
  }

  Future<void> _togglePause(Map<String, dynamic> transaction) async {
    final id = transaction['id'].toString();
    final isActive = transaction['is_active'] == true;

    try {
      if (isActive) {
        await _apiService.pauseRecurringTransaction(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaksi dijeda'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await _apiService.resumeRecurringTransaction(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaksi dilanjutkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      _loadRecurringTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              'Hapus Transaksi Berulang?',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Transaksi "${transaction['description']}" akan dihapus permanen.',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Hapus',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteRecurringTransaction(
          transaction['id'].toString(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaksi berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _loadRecurringTransactions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaksi Berulang',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Iconsax.eye : Iconsax.eye_slash,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showActiveOnly = !_showActiveOnly;
              });
              _loadRecurringTransactions();
            },
            tooltip: _showActiveOnly ? 'Tampilkan Semua' : 'Tampilkan Aktif',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh, color: Colors.white),
            onPressed: _loadRecurringTransactions,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
              )
              : _recurringTransactions.isEmpty
              ? _buildEmptyState()
              : _buildTransactionsList(),
      floatingActionButton: FloatingActionButton(
        heroTag: 'recurring_fab',
        onPressed: () {
          // TODO: Open add recurring transaction modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fitur tambah transaksi berulang segera hadir'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        backgroundColor: const Color(0xFF8B5FBF),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.repeat, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi berulang',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap tombol + untuk membuat',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recurringTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _recurringTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type']?.toString().toLowerCase() ?? 'expense';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final description = transaction['description'] ?? 'Transaksi';
    final frequency = transaction['frequency'] ?? 'monthly';
    final isActive = transaction['is_active'] == true;
    final nextDate = transaction['next_date'];

    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isActive
                  ? typeColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            description,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Dijeda',
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5FBF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Iconsax.repeat,
                                size: 10,
                                color: Color(0xFF8B5FBF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getFrequencyText(frequency),
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF8B5FBF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (nextDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Berikutnya: $nextDate',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    type == 'income'
                        ? '+${CurrencyFormatter.formatRupiah(amount)}'
                        : '-${CurrencyFormatter.formatRupiah(amount)}',
                    style: GoogleFonts.poppins(
                      color: typeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: isActive ? Iconsax.pause : Iconsax.play,
                  label: isActive ? 'Jeda' : 'Lanjut',
                  color: isActive ? Colors.orange : Colors.green,
                  onTap: () => _togglePause(transaction),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.edit,
                  label: 'Edit',
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur edit segera hadir'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Iconsax.trash,
                  label: 'Hapus',
                  color: Colors.red,
                  onTap: () => _deleteTransaction(transaction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
