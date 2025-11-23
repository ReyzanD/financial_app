import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/budgets/add_budget_modal.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _activeOnly = true;

  List<Map<String, dynamic>> _budgets = [];
  Map<String, String> _categories = {};
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getBudgets(activeOnly: _activeOnly),
        _apiService.getBudgetsSummary(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      final categories = results[0] as List<dynamic>;
      final budgets = results[1] as List<dynamic>;
      final summary = results[2] as Map<String, dynamic>;

      final categoryMap = <String, String>{};
      for (final cat in categories) {
        final id = cat['id'];
        final name = cat['name'];
        if (id != null && name != null) {
          categoryMap[id.toString()] = name.toString();
        }
      }

      if (!mounted) return;

      setState(() {
        _categories = categoryMap;
        _budgets = budgets.map((b) => b as Map<String, dynamic>).toList();
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('timeout')) {
      return 'Koneksi timeout. Cek koneksi internet Anda.';
    } else if (errorStr.contains('connection') ||
        errorStr.contains('network')) {
      return 'Gagal terhubung ke server. Pastikan backend berjalan.';
    } else if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return 'Sesi berakhir. Silakan login kembali.';
    } else {
      return 'Gagal memuat data budget.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF8B5FBF),
                backgroundColor: const Color(0xFF1A1A1A),
                onRefresh: _loadData,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'budgets_fab',
        backgroundColor: const Color(0xFF8B5FBF),
        onPressed: _showAddBudgetModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Budget',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _activeOnly ? 'Aktif' : 'Semua',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _activeOnly,
                activeColor: const Color(0xFF8B5FBF),
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[800],
                onChanged: (value) {
                  setState(() {
                    _activeOnly = value;
                  });
                  _loadData();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_summary != null) _buildSummaryRow(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final totalBudget = (_summary?['total_budget'] as num?)?.toDouble() ?? 0;
    final totalSpent = (_summary?['total_spent'] as num?)?.toDouble() ?? 0;
    final totalRemaining =
        (_summary?['total_remaining'] as num?)?.toDouble() ?? 0;

    return Row(
      children: [
        _buildSummaryChip('Total Budget', totalBudget),
        const SizedBox(width: 8),
        _buildSummaryChip('Terpakai', totalSpent),
        const SizedBox(width: 8),
        _buildSummaryChip('Sisa', totalRemaining),
      ],
    );
  }

  Widget _buildSummaryChip(String label, double amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.formatRupiah(amount.toInt()),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 40),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat budget',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadData,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_budgets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                Icon(Icons.wallet_outlined, color: Colors.grey[600], size: 48),
                const SizedBox(height: 12),
                Text(
                  'Belum ada budget',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tambahkan budget untuk mulai mengatur pengeluaran.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _budgets.length,
      itemBuilder: (context, index) {
        final budget = _budgets[index];
        return _buildBudgetItem(budget);
      },
    );
  }

  Widget _buildBudgetItem(Map<String, dynamic> budget) {
    final categoryId = budget['category_id']?.toString();
    final category =
        categoryId != null && _categories.containsKey(categoryId)
            ? _categories[categoryId]!
            : 'Semua Kategori';

    final amount = (budget['amount'] as num?)?.toDouble() ?? 0.0;
    final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
    final remaining = amount - spent;
    final period = (budget['period'] as String?) ?? '-';
    final isActive = (budget['is_active'] as bool?) ?? true;

    final percentage = amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > amount && amount > 0;
    final color = _getCategoryColor(category);
    final displayColor = isOverBudget ? Colors.red : color;

    return InkWell(
      onTap: () {
        _openBudgetModal(budget);
      },
      onLongPress: () {
        _confirmDeleteBudget(budget);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isOverBudget ? Colors.red.withOpacity(0.4) : Colors.grey[800]!,
            width: isOverBudget ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: displayColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isOverBudget) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatRupiah(spent.toInt()),
                      style: GoogleFonts.poppins(
                        color: displayColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'dari ${CurrencyFormatter.formatRupiah(amount.toInt())}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Periode: $period',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nonaktif',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[300],
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[850],
                valueColor: AlwaysStoppedAnimation(displayColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOverBudget
                      ? 'Melebihi ${CurrencyFormatter.formatRupiah((spent - amount).toInt())}'
                      : 'Sisa ${CurrencyFormatter.formatRupiah(remaining.toInt())}',
                  style: GoogleFonts.poppins(
                    color: isOverBudget ? Colors.red[300] : Colors.green[300],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    color: displayColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return const Color(0xFFE74C3C);
      case 'transportasi':
        return const Color(0xFFF39C12);
      case 'hiburan':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF8B5FBF);
    }
  }

  Future<void> _showAddBudgetModal() async {
    await _openBudgetModal();
  }

  Future<void> _openBudgetModal([Map<String, dynamic>? budget]) async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddBudgetModal(categories: _categories, initialBudget: budget);
      },
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _confirmDeleteBudget(Map<String, dynamic> budget) async {
    final id = budget['id']?.toString();
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Hapus Budget',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Yakin ingin menghapus budget ini?',
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteBudget(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget berhasil dihapus.'),
            backgroundColor: Color(0xFF8B5FBF),
          ),
        );
        await _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
