import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/Screen/report_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ApiService _apiService = ApiService();
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
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyAllFilters();
    });
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
      final data = await _apiService.getTransactions(
        limit: _pageSize,
        offset: _currentOffset,
      );
      final transactions = List<Map<String, dynamic>>.from(
        data['transactions'] ?? [],
      );

      // Sort by date descending (newest first) initially
      transactions.sort((a, b) {
        final dateA = DateTime.parse(
          a['date'] ?? DateTime.now().toIso8601String(),
        );
        final dateB = DateTime.parse(
          b['date'] ?? DateTime.now().toIso8601String(),
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

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  void _applyFilter(String filterType) {
    setState(() {
      _filterType = filterType;
      _applyAllFilters();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _filterType = 'all';
      _selectedCategory = 'all';
      _dateRange = null;
      _searchQuery = '';
      _searchController.clear();
      _applyAllFilters();
    });
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'date_desc':
          _filteredTransactions.sort((a, b) {
            final dateA = DateTime.parse(
              a['date'] ?? DateTime.now().toIso8601String(),
            );
            final dateB = DateTime.parse(
              b['date'] ?? DateTime.now().toIso8601String(),
            );
            return dateB.compareTo(dateA);
          });
          break;
        case 'date_asc':
          _filteredTransactions.sort((a, b) {
            final dateA = DateTime.parse(
              a['date'] ?? DateTime.now().toIso8601String(),
            );
            final dateB = DateTime.parse(
              b['date'] ?? DateTime.now().toIso8601String(),
            );
            return dateA.compareTo(dateB);
          });
          break;
        case 'amount_desc':
          _filteredTransactions.sort((a, b) {
            final amountA = (a['amount'] ?? 0).toDouble();
            final amountB = (b['amount'] ?? 0).toDouble();
            return amountB.compareTo(amountA);
          });
          break;
        case 'amount_asc':
          _filteredTransactions.sort((a, b) {
            final amountA = (a['amount'] ?? 0).toDouble();
            final amountB = (b['amount'] ?? 0).toDouble();
            return amountA.compareTo(amountB);
          });
          break;
      }
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
          'Riwayat Transaksi',
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
                  builder: (context) => const ReportScreen(),
                ),
              );
            },
            tooltip: 'Buat Laporan',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _loadTransactions(reset: true),
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
              )
              : Column(
                children: [
                  _buildSummaryCard(),
                  _buildFiltersAndSort(),
                  Expanded(child: _buildTransactionsList()),
                ],
              ),
    );
  }

  Widget _buildSummaryCard() {
    final totalIncome = _transactions
        .where((t) => t['type']?.toString().toLowerCase() == 'income')
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0).toDouble());

    final totalExpense = _transactions
        .where((t) => t['type']?.toString().toLowerCase() == 'expense')
        .fold(0.0, (sum, t) => sum + (t['amount'] ?? 0).toDouble());

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5FBF), Color(0xFF6A3093)],
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
                'Total Pemasukan',
                totalIncome,
                const Color(0xFF4CAF50),
                Icons.trending_up_rounded,
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildSummaryItem(
                'Total Pengeluaran',
                totalExpense,
                const Color(0xFFF44336),
                Icons.trending_down_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Saldo Akhir: ',
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
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari transaksi...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF8B5FBF),
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
          const SizedBox(height: 12),
          // Filter chips
          Row(
            children: [
              Text(
                'Filter: ',
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
                      _buildFilterChip('Semua', 'all'),
                      _buildFilterChip('Pemasukan', 'income'),
                      _buildFilterChip('Pengeluaran', 'expense'),
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
                    color: Color(0xFF8B5FBF),
                    size: 20,
                  ),
                  onPressed: _clearAllFilters,
                  tooltip: 'Reset Filter',
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Sort dropdown
          Row(
            children: [
              Text(
                'Urutkan: ',
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
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8B5FBF).withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      dropdownColor: const Color(0xFF1A1A1A),
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
                      items: const [
                        DropdownMenuItem(
                          value: 'date_desc',
                          child: Text('Tanggal Terbaru'),
                        ),
                        DropdownMenuItem(
                          value: 'date_asc',
                          child: Text('Tanggal Terlama'),
                        ),
                        DropdownMenuItem(
                          value: 'amount_desc',
                          child: Text('Jumlah Terbesar'),
                        ),
                        DropdownMenuItem(
                          value: 'amount_asc',
                          child: Text('Jumlah Terkecil'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.2)),
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
                isSelected ? const Color(0xFF8B5FBF) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? const Color(0xFF8B5FBF)
                      : Colors.grey.withOpacity(0.3),
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
        child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
      );
    }

    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada transaksi',
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTransactions.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredTransactions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
            ),
          );
        }
        final transaction = _filteredTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: typeColor.withOpacity(0.3),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.2),
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Saldo: ${_formatCurrency(runningBalance)}',
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
