import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/features/analytics/presentation/screens/analytics_hub_screen.dart';
import 'package:financial_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/widgets/common/responsive_content.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TransactionDataService _transactionData =
      getIt<TransactionDataService>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 50;
  String _filterType = 'all'; // all, income, expense
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  String _searchQuery = '';
  String _selectedCategory = 'all';
  DateTimeRange? _dateRange;
  double _runningBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreTransactions();
      }
    }
  }

  void _onSearchChanged() {
    _searchQuery = _searchController.text.toLowerCase();
    _applyAllFilters();
  }

  Future<void> _loadTransactions({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentOffset = 0;
        _transactions = [];
        _hasMore = true;
      });
    }

    try {
      final data = await _transactionData.getTransactions(
        limit: _pageSize,
        offset: _currentOffset,
      );
      final transactions = List<Map<String, dynamic>>.from(
        data['transactions'] ?? [],
      );

      // Sort by date descending (newest first) initially
      transactions.sort((a, b) {
        final dateA = DateTime.parse(
          (a['transaction_date_232143'] ??
              a['date'] ??
              DateTime.now().toIso8601String()),
        );
        final dateB = DateTime.parse(
          (b['transaction_date_232143'] ??
              b['date'] ??
              DateTime.now().toIso8601String()),
        );
        return dateB.compareTo(dateA);
      });

      setState(() {
        if (reset) {
          _transactions = transactions;
        } else {
          _transactions.addAll(transactions);
        }
        _currentOffset += transactions.length;
        _hasMore = transactions.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });

      // Calculate running balance after loading
      _calculateRunningBalance(_transactions);
      _applyAllFilters();
    } catch (e) {
      LoggerService.error('Error loading transactions', error: e);
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: () => _loadTransactions(reset: true),
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    await _loadTransactions(reset: false);
  }

  void _calculateRunningBalance(List<Map<String, dynamic>> transactions) {
    if (transactions.isEmpty) {
      _runningBalance = 0;
      return;
    }

    // Start from oldest transaction (reverse the list)
    final reversed = transactions.reversed.toList();
    double balance = 0;

    for (var transaction in reversed) {
      final amountRaw = transaction['amount'];
      final amount =
          amountRaw is num
              ? amountRaw.toDouble()
              : (double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0);

      final typeRaw = transaction['type'];
      final type = typeRaw?.toString().toLowerCase() ?? 'expense';

      if (type == 'income') {
        balance += amount;
      } else if (type == 'expense') {
        balance -= amount;
      }

      transaction['running_balance'] = balance;
    }

    _runningBalance = balance;
  }

  void _applyAllFilters() {
    List<Map<String, dynamic>> filtered = List.from(_transactions);

    // Apply type filter
    if (_filterType != 'all') {
      filtered =
          filtered
              .where((t) => t['type']?.toString().toLowerCase() == _filterType)
              .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'all') {
      filtered =
          filtered
              .where((t) => t['category_name']?.toString() == _selectedCategory)
              .toList();
    }

    // Apply date range filter
    if (_dateRange != null) {
      filtered =
          filtered.where((t) {
            try {
              final date = DateTime.parse(t['date'] ?? '');
              return date.isAfter(
                    _dateRange!.start.subtract(const Duration(days: 1)),
                  ) &&
                  date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((t) {
            final description =
                (t['description'] ?? '').toString().toLowerCase();
            final category =
                (t['category_name'] ?? '').toString().toLowerCase();
            final amount = (t['amount'] ?? 0).toString();
            final notes = (t['notes'] ?? '').toString().toLowerCase();

            return description.contains(_searchQuery) ||
                category.contains(_searchQuery) ||
                amount.contains(_searchQuery) ||
                notes.contains(_searchQuery);
          }).toList();
    }

    // Apply current sort order
    _sortList(filtered);

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  /// Apply the current sort order to the given list and update state once.
  /// Sort the given list in-place using the current _sortBy setting.
  void _sortList(List<Map<String, dynamic>> list) {
    switch (_sortBy) {
      case 'date_desc':
        list.sort((a, b) {
          final dateA = DateTime.parse(
            (a['transaction_date_232143'] ??
                a['date'] ??
                DateTime.now().toIso8601String()),
          );
          final dateB = DateTime.parse(
            (b['transaction_date_232143'] ??
                b['date'] ??
                DateTime.now().toIso8601String()),
          );
          return dateB.compareTo(dateA);
        });
        break;
      case 'date_asc':
        list.sort((a, b) {
          final dateA = DateTime.parse(
            (a['transaction_date_232143'] ??
                a['date'] ??
                DateTime.now().toIso8601String()),
          );
          final dateB = DateTime.parse(
            (b['transaction_date_232143'] ??
                b['date'] ??
                DateTime.now().toIso8601String()),
          );
          return dateA.compareTo(dateB);
        });
        break;
      case 'amount_desc':
        list.sort((a, b) {
          final amountA = (a['amount'] ?? 0).toDouble();
          final amountB = (b['amount'] ?? 0).toDouble();
          return amountB.compareTo(amountA);
        });
        break;
      case 'amount_asc':
        list.sort((a, b) {
          final amountA = (a['amount'] ?? 0).toDouble();
          final amountB = (b['amount'] ?? 0).toDouble();
          return amountA.compareTo(amountB);
        });
        break;
    }
  }

  void _applyFilter(String filterType) {
    _filterType = filterType;
    _applyAllFilters();
  }

  void _clearAllFilters() {
    _filterType = 'all';
    _selectedCategory = 'all';
    _dateRange = null;
    _searchQuery = '';
    _searchController.clear();
    _applyAllFilters();
  }

  void _applySorting() {
    setState(() {
      _sortList(_filteredTransactions);
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
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
        return Icons.trending_up_rounded;
      case 'expense':
        return Icons.trending_down_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: l10n?.back ?? 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n?.transaction_history ?? 'Riwayat Transaksi',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const AnalyticsHubScreen(initialTab: 'reports'),
                ),
              );
            },
            tooltip: l10n?.create_report ?? 'Buat Laporan',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _loadTransactions(reset: true),
            tooltip: l10n?.reload_tooltip ?? 'Muat Ulang',
          ),
        ],
      ),
      body: ResponsiveContent(
        child: Column(
          children: [
            const OfflineIndicator(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: DesignTokens.primaryColor,
                        ),
                      )
                      : Column(
                        children: [
                          _buildSummaryCard(),
                          _buildFiltersAndSort(),
                          Expanded(child: _buildTransactionsList()),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final l10n = AppLocalizations.of(context);
    final totalIncome = _transactions
        .where((t) => t['type']?.toString().toLowerCase() == 'income')
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0).toDouble());

    final totalExpense = _transactions
        .where((t) => t['type']?.toString().toLowerCase() == 'expense')
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0).toDouble());

    return Container(
      margin: const EdgeInsets.all(DesignTokens.spacing4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DesignTokens.primaryColor, DesignTokens.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                l10n?.total_income ?? 'Total Pemasukan',
                totalIncome,
                DesignTokens.successColor,
                Icons.trending_up_rounded,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildSummaryItem(
                l10n?.total_expense ?? 'Total Pengeluaran',
                totalExpense,
                DesignTokens.errorColor,
                Icons.trending_down_rounded,
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${l10n?.balance ?? 'Saldo'}: ',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatCurrency(_runningBalance),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
          Text(
            _formatCurrency(amount),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersAndSort() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n?.search_transactions ?? 'Cari transaksi...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: DesignTokens.primaryColor,
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
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
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                borderSide: BorderSide(color: DesignTokens.borderDark),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                borderSide: BorderSide(color: DesignTokens.borderDark),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                borderSide: const BorderSide(
                  color: DesignTokens.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
          // Filter chips
          Row(
            children: [
              Text(
                '${l10n?.filter ?? 'Filter'}: ',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(l10n?.all ?? 'Semua', 'all'),
                      _buildFilterChip(l10n?.income ?? 'Pemasukan', 'income'),
                      _buildFilterChip(
                        l10n?.expense ?? 'Pengeluaran',
                        'expense',
                      ),
                    ],
                  ),
                ),
              ),
              // Clear filters button
              if (_searchQuery.isNotEmpty ||
                  _filterType != 'all' ||
                  _selectedCategory != 'all' ||
                  _dateRange != null)
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: DesignTokens.primaryColor,
                    size: 20,
                  ),
                  onPressed: _clearAllFilters,
                  tooltip: l10n?.reset_filter ?? 'Reset Filter',
                ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
          // Sort dropdown
          Row(
            children: [
              Text(
                l10n?.sort_by ?? 'Urutkan: ',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: DesignTokens.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: DesignTokens.surfaceDark,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortBy = value;
                            _applySorting();
                          });
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'date_desc',
                          child: Text(l10n?.newest_date ?? 'Newest Date'),
                        ),
                        DropdownMenuItem(
                          value: 'date_asc',
                          child: Text(l10n?.oldest_date ?? 'Oldest Date'),
                        ),
                        DropdownMenuItem(
                          value: 'amount_desc',
                          child: Text(l10n?.highest_amount ?? 'Highest Amount'),
                        ),
                        DropdownMenuItem(
                          value: 'amount_asc',
                          child: Text(l10n?.lowest_amount ?? 'Lowest Amount'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _applyFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? DesignTokens.primaryColor
                    : DesignTokens.surfaceDark,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            border: Border.all(
              color:
                  isSelected
                      ? DesignTokens.primaryColor
                      : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading && _transactions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Center(
        child: EmptyStates.noTransactions(
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          ),
          context,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: _filteredTransactions.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredTransactions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: DesignTokens.primaryColor,
              ),
            ),
          );
        }
        final transaction = _filteredTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final l10n = AppLocalizations.of(context);
    final type = transaction['type']?.toString().toLowerCase() ?? 'expense';
    final amount = (transaction['amount'] ?? 0).toDouble();
    final runningBalance = (transaction['running_balance'] ?? 0).toDouble();
    final description = transaction['description'] ?? 'Transaksi';
    final date = transaction['date'] ?? DateTime.now().toIso8601String();
    final category = transaction['category_name'] ?? type;

    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: typeColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: typeColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(typeIcon, color: typeColor, size: 26),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: typeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(date),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${l10n?.balance ?? 'Saldo'}: ${_formatCurrency(runningBalance)}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                type == 'income'
                    ? '+${_formatCurrency(amount)}'
                    : '-${_formatCurrency(amount)}',
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
    );
  }
}
