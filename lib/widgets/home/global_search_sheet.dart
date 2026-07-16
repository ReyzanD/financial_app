import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/formatters.dart';

/// Global search overlay shown as a bottom sheet from the home header.
///
/// Searches across transactions, budgets, and goals.
class GlobalSearchSheet extends StatefulWidget {
  const GlobalSearchSheet({super.key});

  @override
  State<GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<GlobalSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TransactionDataService _transactionData =
      getIt<TransactionDataService>();
  final BudgetDataService _budgetData = getIt<BudgetDataService>();
  final GoalDataService _goalData = getIt<GoalDataService>();
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  List<Map<String, dynamic>> _filteredBudgets = [];
  List<Map<String, dynamic>> _filteredGoals = [];
  bool _isLoading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _query) {
        setState(() {
          _query = q;
          _filterResults();
        });
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _transactionData.getTransactions(limit: 200),
        _budgetData.getBudgets().then((m) => m.map((b) => b.toJson()).toList()),
        _goalData.getGoals().then((m) => m.map((g) => g.toJson()).toList()),
      ]);
      if (!mounted) return;
      setState(() {
        final txnData = results[0] as Map<String, dynamic>? ?? {};
        _transactions =
            (txnData['transactions'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        _budgets =
            (results[1] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _goals =
            (results[2] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _isLoading = false;
        _filterResults();
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterResults() {
    if (_query.isEmpty) {
      _filteredTransactions = [];
      _filteredBudgets = [];
      _filteredGoals = [];
      return;
    }

    _filteredTransactions =
        _transactions.where((t) {
          final desc = (t['description'] as String? ?? '').toLowerCase();
          final cat = (t['category_name'] as String? ?? '').toLowerCase();
          final amount = (t['amount'] as num?)?.toDouble() ?? 0;
          return desc.contains(_query) ||
              cat.contains(_query) ||
              amount.toString().contains(_query);
        }).toList();

    _filteredBudgets =
        _budgets.where((b) {
          final name = (b['category_name'] as String? ?? '').toLowerCase();
          final amount = (b['amount'] as num?)?.toDouble() ?? 0;
          return name.contains(_query) || amount.toString().contains(_query);
        }).toList();

    _filteredGoals =
        _goals.where((g) {
          final name = (g['name'] as String? ?? '').toLowerCase();
          final desc = (g['description'] as String? ?? '').toLowerCase();
          final target = (g['target_amount'] as num?)?.toDouble() ?? 0;
          return name.contains(_query) ||
              desc.contains(_query) ||
              target.toString().contains(_query);
        }).toList();
  }

  int get _totalResults =>
      _filteredTransactions.length +
      _filteredBudgets.length +
      _filteredGoals.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: DesignTokens.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Cari transaksi, anggaran, tujuan...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                prefixIcon: const Icon(
                  Iconsax.search_normal_1,
                  color: Colors.grey,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(
                            Iconsax.close_circle,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                filled: true,
                fillColor: DesignTokens.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Results
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.primaryColor,
                      ),
                    )
                    : _query.isEmpty
                    ? _buildEmptyHint()
                    : _totalResults == 0
                    ? _buildNoResults()
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.search_normal_1, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            'Cari transaksi, anggaran, atau tujuan',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.document_text, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 12),
          Text(
            'Tidak ditemukan untuk "$_query"',
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '$_totalResults hasil untuk "$_query"',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
          ),
        ),
        // Transactions
        if (_filteredTransactions.isNotEmpty) ...[
          _buildSectionHeader(
            Iconsax.receipt,
            'Transaksi (${_filteredTransactions.length})',
          ),
          ..._filteredTransactions
              .take(10)
              .map((t) => _buildTransactionTile(t)),
          if (_filteredTransactions.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                '+${_filteredTransactions.length - 10} transaksi lainnya',
                style: GoogleFonts.poppins(
                  color: DesignTokens.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        // Budgets
        if (_filteredBudgets.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSectionHeader(
            Iconsax.wallet,
            'Anggaran (${_filteredBudgets.length})',
          ),
          ..._filteredBudgets.take(10).map((b) => _buildBudgetTile(b)),
          if (_filteredBudgets.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                '+${_filteredBudgets.length - 10} anggaran lainnya',
                style: GoogleFonts.poppins(
                  color: DesignTokens.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        // Goals
        if (_filteredGoals.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSectionHeader(
            Iconsax.flag,
            'Tujuan (${_filteredGoals.length})',
          ),
          ..._filteredGoals.take(10).map((g) => _buildGoalTile(g)),
          if (_filteredGoals.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                '+${_filteredGoals.length - 10} tujuan lainnya',
                style: GoogleFonts.poppins(
                  color: DesignTokens.primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DesignTokens.primaryColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> t) {
    final isIncome = t['type'] == 'income';
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
    final desc = t['description'] as String? ?? 'Tanpa keterangan';
    final cat = t['category_name'] as String? ?? '';
    final date = t['transaction_date'] as String? ?? '';

    return _buildResultTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isIncome
                  ? DesignTokens.successColor
                  : DesignTokens.errorColor)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isIncome ? Iconsax.arrow_down_1 : Iconsax.arrow_up_3,
          color: isIncome ? DesignTokens.successColor : DesignTokens.errorColor,
          size: 18,
        ),
      ),
      title: desc,
      subtitle: '$cat • $date',
      trailing: Text(
        '${isIncome ? '+' : '-'}${CurrencyFormatter.formatRupiah(amount.toInt())}',
        style: GoogleFonts.poppins(
          color: isIncome ? DesignTokens.successColor : DesignTokens.errorColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(
          context,
          '/transaction-detail',
          arguments: {'id': t['transaction_id_232143'] ?? t['id']},
        );
      },
    );
  }

  Widget _buildBudgetTile(Map<String, dynamic> b) {
    final catName = b['category_name'] as String? ?? 'Tanpa kategori';
    final amount = (b['amount'] as num?)?.toDouble() ?? 0;

    return _buildResultTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: DesignTokens.primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Iconsax.wallet,
          color: DesignTokens.primaryColor,
          size: 18,
        ),
      ),
      title: catName,
      subtitle: 'Anggaran ${CurrencyFormatter.formatRupiah(amount.toInt())}',
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/budgets');
      },
    );
  }

  Widget _buildGoalTile(Map<String, dynamic> g) {
    final name = g['name'] as String? ?? 'Tanpa nama';
    final target = (g['target_amount'] as num?)?.toDouble() ?? 0;

    return _buildResultTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: DesignTokens.warningColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Iconsax.flag,
          color: DesignTokens.warningColor,
          size: 18,
        ),
      ),
      title: name,
      subtitle: 'Target ${CurrencyFormatter.formatRupiah(target.toInt())}',
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/goals');
      },
    );
  }

  Widget _buildResultTile({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                : null,
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}
