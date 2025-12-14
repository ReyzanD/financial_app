import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/app_refresh.dart';

class QuickAddWidget extends StatefulWidget {
  final VoidCallback? onTransactionAdded;

  const QuickAddWidget({super.key, this.onTransactionAdded});

  @override
  State<QuickAddWidget> createState() => _QuickAddWidgetState();
}

class _QuickAddWidgetState extends State<QuickAddWidget> {
  final ApiService _apiService = ApiService();
  List<dynamic> _recentCategories = [];
  bool _isLoadingCategories = true;

  // Quick amount presets in IDR
  final List<double> _quickAmounts = [
    10000,
    25000,
    50000,
    100000,
    250000,
    500000,
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentCategories();
  }

  Future<void> _loadRecentCategories() async {
    try {
      // Get all categories (will use cache if available)
      final categories = await _apiService.getCategories();

      // Get recent transactions to find most used categories (reduced from 50 to 20)
      final transactions = await _apiService.getTransactions(limit: 20);

      // Count category usage
      final Map<String, int> categoryUsageCount = {};
      for (var transaction in transactions) {
        final categoryId = transaction['category_id'];
        if (categoryId != null) {
          final idString = categoryId.toString();
          categoryUsageCount[idString] =
              (categoryUsageCount[idString] ?? 0) + 1;
        }
      }

      // Convert categories to list with usage count
      final List<Map<String, dynamic>> categoryList = [];
      for (var category in categories) {
        if (category != null &&
            category['id'] != null &&
            category['name'] != null) {
          final idString = category['id'].toString();
          categoryList.add({
            'id': idString,
            'name': category['name'].toString(),
            'count': categoryUsageCount[idString] ?? 0,
          });
        }
      }

      // Sort by usage (most used first), then alphabetically
      categoryList.sort((a, b) {
        final countCompare = b['count'].compareTo(a['count']);
        if (countCompare != 0) return countCompare;
        return a['name'].toString().compareTo(b['name'].toString());
      });

      if (mounted) {
        setState(() {
          _recentCategories = categoryList.take(6).toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading recent categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _quickAddTransaction({
    required String type,
    double? amount,
    String? categoryId,
  }) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
            ),
      );

      // If no amount or category, show full modal
      if (amount == null || categoryId == null) {
        Navigator.pop(context); // Close loading
        _showQuickAddModal(type: type, presetAmount: amount);
        return;
      }

      // Create transaction
      await _apiService.addTransaction({
        'description': 'Quick ${type == 'income' ? 'Income' : 'Expense'}',
        'amount': amount,
        'type': type,
        'category_id': categoryId,
        'date': DateTime.now().toIso8601String(),
      });

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Transaksi ${CurrencyFormatter.formatRupiah(amount)} berhasil ditambahkan!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Trigger immediate refresh
      if (mounted) await AppRefresh.refreshAll(context);

      // Callback to refresh parent
      widget.onTransactionAdded?.call();
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);

      // Show error
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

  void _showQuickAddModal({
    required String type,
    double? presetAmount,
    String? presetCategoryId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => QuickAddModal(
            type: type,
            presetAmount: presetAmount,
            presetCategoryId: presetCategoryId,
            onTransactionAdded: widget.onTransactionAdded,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Iconsax.flash_1, color: Color(0xFF8B5FBF), size: 20),
              const SizedBox(width: 8),
              Text(
                'Tambah Cepat',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick type buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickTypeButton(
                  label: 'Pemasukan',
                  icon: Iconsax.arrow_down_1,
                  color: Colors.green,
                  type: 'income',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickTypeButton(
                  label: 'Pengeluaran',
                  icon: Iconsax.arrow_up_3,
                  color: Colors.red,
                  type: 'expense',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick amounts section
          Text(
            'Nominal Cepat',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _quickAmounts.map((amount) {
                  return _buildAmountChip(amount);
                }).toList(),
          ),

          // Recent categories section
          const SizedBox(height: 16),
          Text(
            'Kategori Sering',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingCategories)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF8B5FBF),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_recentCategories.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Belum ada kategori yang sering digunakan',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _recentCategories.map((category) {
                    return _buildCategoryChip(category);
                  }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickTypeButton({
    required String label,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return GestureDetector(
      onTap: () => _showQuickAddModal(type: type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChip(double amount) {
    return GestureDetector(
      onTap: () => _showQuickAddModal(type: 'expense', presetAmount: amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5FBF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF8B5FBF).withOpacity(0.5)),
        ),
        child: Text(
          CurrencyFormatter.formatRupiah(amount),
          style: GoogleFonts.poppins(
            color: const Color(0xFF8B5FBF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> category) {
    return GestureDetector(
      onTap:
          () => _showQuickAddModal(
            type: 'expense',
            presetCategoryId: category['id'].toString(),
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.category, size: 14, color: Colors.blue),
            const SizedBox(width: 6),
            Text(
              category['name'].toString(),
              style: GoogleFonts.poppins(
                color: Colors.blue,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Add Modal for full transaction entry
class QuickAddModal extends StatefulWidget {
  final String type;
  final double? presetAmount;
  final String? presetCategoryId;
  final VoidCallback? onTransactionAdded;

  const QuickAddModal({
    super.key,
    required this.type,
    this.presetAmount,
    this.presetCategoryId,
    this.onTransactionAdded,
  });

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final ApiService _apiService = ApiService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    if (widget.presetAmount != null) {
      _amountController.text = widget.presetAmount!.toInt().toString();
    }
    _selectedCategoryId = widget.presetCategoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _categories =
              categories
                  .where(
                    (cat) =>
                        cat != null && cat['id'] != null && cat['name'] != null,
                  )
                  .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat kategori: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _checkBalanceBeforeExpense(double expenseAmount) async {
    try {
      // Get current financial summary
      final summary = await _apiService.getFinancialSummary();
      final summaries = summary['summary'] as Map<String, dynamic>?;

      if (summaries == null) return true; // Allow if we can't check

      final income =
          (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;
      final expense =
          (summaries['expense'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;
      final currentBalance = income - expense;
      final newBalance = currentBalance - expenseAmount;

      // Minimum balance requirement: 25000
      const double minimumBalance = 25000.0;

      // If balance would go below the minimum, block the transaction
      if (newBalance < minimumBalance) {
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saldo Tidak Cukup',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaksi ditolak! Saldo Anda tidak mencukupi untuk pengeluaran ini.',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _buildBalanceRow(
                            'Saldo Tersedia',
                            currentBalance,
                            Colors.white70,
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceRow(
                            'Saldo Minimum',
                            minimumBalance,
                            Colors.orange[300]!,
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceRow(
                            'Pengeluaran',
                            expenseAmount,
                            Colors.red[300]!,
                          ),
                          const Divider(color: Colors.grey, height: 20),
                          _buildBalanceRow(
                            'Kekurangan',
                            (minimumBalance - newBalance).abs(),
                            Colors.red[400]!,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue[300],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tambahkan pemasukan terlebih dahulu atau kurangi jumlah pengeluaran.',
                              style: GoogleFonts.poppins(
                                color: Colors.blue[300],
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5FBF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Text(
                      'Mengerti',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
        );
        return false; // Block the transaction
      }

      return true; // Balance is fine, proceed
    } catch (e) {
      print('Error checking balance: $e');
      return true; // Allow transaction if check fails
    }
  }

  Widget _buildBalanceRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.formatRupiah(amount.abs()),
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _submitTransaction() async {
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah yang valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check balance before adding expense
    if (widget.type == 'expense') {
      final shouldContinue = await _checkBalanceBeforeExpense(amount);
      if (!shouldContinue) {
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.addTransaction({
        'description':
            description.isEmpty
                ? 'Quick ${widget.type == 'income' ? 'Income' : 'Expense'}'
                : description,
        'amount': amount,
        'type': widget.type,
        'category_id': _selectedCategoryId,
        'date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        // Trigger immediate refresh
        await AppRefresh.refreshAll(context);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Transaksi berhasil ditambahkan!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onTransactionAdded?.call();
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final typeColor = widget.type == 'income' ? Colors.green : Colors.red;
    final typeIcon =
        widget.type == 'income' ? Iconsax.arrow_down_1 : Iconsax.arrow_up_3;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.type == 'income'
                        ? 'Tambah Pemasukan'
                        : 'Tambah Pengeluaran',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount
            Text(
              'Jumlah',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Rp 0',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B5FBF),
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(Iconsax.money_4, color: typeColor),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            Text(
              'Kategori',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingCategories
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
                )
                : _categories.isEmpty
                ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.info_circle,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tidak ada kategori. Buat kategori terlebih dahulu di menu Budget.',
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: GoogleFonts.poppins(color: Colors.white),
                  hint: Text(
                    'Pilih kategori',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[800]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF8B5FBF),
                        width: 2,
                      ),
                    ),
                  ),
                  items:
                      _categories.map((category) {
                        final id = category['id']?.toString() ?? '';
                        final name = category['name']?.toString() ?? 'Unknown';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
            const SizedBox(height: 16),

            // Description (optional)
            Text(
              'Deskripsi (Opsional)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tambahkan deskripsi...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B5FBF),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Tambah Transaksi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
