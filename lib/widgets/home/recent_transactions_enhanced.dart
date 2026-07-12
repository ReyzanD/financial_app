import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/features/transactions/presentation/screens/transaction_screen.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/services/search_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';

/// Enhanced Recent Transactions dengan search, filter, dan swipe actions
class RecentTransactionsEnhanced extends StatefulWidget {
  const RecentTransactionsEnhanced({super.key});

  @override
  State<RecentTransactionsEnhanced> createState() =>
      _RecentTransactionsEnhancedState();
}

class _RecentTransactionsEnhancedState
    extends State<RecentTransactionsEnhanced> {
  final SearchService _searchService = getIt<SearchService>();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedType; // 'income', 'expense', null for all
  String? _selectedCategoryId;
  List<TransactionModel> _filteredTransactions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _applyFilters();
  }

  void _applyFilters() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final transactions = await _searchService.searchTransactions(
        query: _searchQuery,
        type: _selectedType,
        categoryId: _selectedCategoryId,
      );

      setState(() {
        _filteredTransactions = transactions.take(10).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Widget _buildTransactionItem(
    TransactionModel transaction,
    BuildContext context,
  ) {
    final isIncome = transaction.type == 'income';

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveHelper.verticalSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 12),
          ),
        ),
        alignment: Alignment.centerLeft,
        padding: ResponsiveHelper.horizontalPadding(context),
        child: Row(
          children: [
            const Icon(Icons.edit, color: Colors.white),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
            Text(
              'Edit',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveHelper.verticalSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 12),
          ),
        ),
        alignment: Alignment.centerRight,
        padding: ResponsiveHelper.horizontalPadding(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
            const Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        final l10n = AppLocalizations.of(context);
        if (direction == DismissDirection.endToStart) {
          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: DesignTokens.surfaceDark,
                      title: Text(
                        l10n?.delete_transaction_confirm ?? 'Hapus Transaksi?',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      content: Text(
                        l10n?.delete_transaction_message_short ??
                            'Apakah Anda yakin ingin menghapus transaksi ini?',
                        style: GoogleFonts.poppins(color: Colors.grey[400]),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            l10n?.cancel ?? 'Batal',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            l10n?.delete ?? 'Hapus',
                            style: GoogleFonts.poppins(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              ) ??
              false;

          if (!confirmed) return false;

          // Perform deletion inside confirmDismiss so the item is NOT
          // removed visually if deletion fails.
          try {
            final ctrl = getIt<TransactionController>();
            await ctrl.deleteTransaction(transaction.id.toString());
            if (!context.mounted) return false;
            ErrorHandlerService.showSuccessSnackbar(
              context,
              l10n?.transaction_deleted_successfully ??
                  'Transaksi berhasil dihapus',
            );
            _applyFilters();
            return true; // Allow dismiss animation
          } catch (e) {
            if (!context.mounted) return false;
            ErrorHandlerService.showErrorSnackbar(
              context,
              l10n?.failed_to_delete_transaction ?? 'Gagal menghapus transaksi',
            );
            return false; // Keep item visible
          }
        }
        return false;
      },
      // onDismissed is intentionally empty — all logic is in confirmDismiss
      onDismissed: (_) {},
      child: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveHelper.verticalSpacing(context, 8),
        ),
        padding: ResponsiveHelper.padding(context, multiplier: 0.75),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 12),
          ),
          border: Border.all(color: DesignTokens.borderDark),
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.iconSize(context, 40),
              height: ResponsiveHelper.iconSize(context, 40),
              decoration: BoxDecoration(
                color: Color(
                  int.parse(transaction.categoryColor.replaceAll('#', '0xFF')),
                ).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.borderRadius(context, 10),
                ),
              ),
              child: Icon(
                isIncome ? Iconsax.arrow_down : Iconsax.arrow_up,
                color: Color(
                  int.parse(transaction.categoryColor.replaceAll('#', '0xFF')),
                ),
                size: ResponsiveHelper.iconSize(context, 20),
              ),
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    transaction.categoryName,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: ResponsiveHelper.fontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatRupiah(
                    transaction.amount.toInt().abs(),
                  ),
                  style: GoogleFonts.poppins(
                    color: isIncome ? Colors.green : Colors.white,
                    fontSize: ResponsiveHelper.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${transaction.transactionDate.hour.toString().padLeft(2, '0')}:${transaction.transactionDate.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: ResponsiveHelper.fontSize(context, 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Use filtered transactions if searching, otherwise use recent transactions
        final transactions =
            _searchQuery.isNotEmpty ||
                    _selectedType != null ||
                    _selectedCategoryId != null
                ? _filteredTransactions
                : appState.transactions.take(10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: ResponsiveHelper.horizontalPadding(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(
                        color: DesignTokens.primaryColor,
                        fontSize: ResponsiveHelper.fontSize(context, 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
            // Search bar
            Padding(
              padding: ResponsiveHelper.horizontalPadding(context),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  prefixIcon: Icon(
                    Iconsax.search_normal,
                    color: Colors.grey[600],
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
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
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
            // Filter chips
            Padding(
              padding: ResponsiveHelper.horizontalPadding(context),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', _selectedType == null, () {
                      setState(() {
                        _selectedType = null;
                      });
                      _applyFilters();
                    }),
                    SizedBox(
                      width: ResponsiveHelper.horizontalSpacing(context, 8),
                    ),
                    _buildFilterChip('Income', _selectedType == 'income', () {
                      setState(() {
                        _selectedType = 'income';
                      });
                      _applyFilters();
                    }),
                    SizedBox(
                      width: ResponsiveHelper.horizontalSpacing(context, 8),
                    ),
                    _buildFilterChip('Expense', _selectedType == 'expense', () {
                      setState(() {
                        _selectedType = 'expense';
                      });
                      _applyFilters();
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
            if (_isSearching)
              Padding(
                padding: ResponsiveHelper.padding(context, multiplier: 2.0),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: DesignTokens.primaryColor,
                  ),
                ),
              )
            else if (transactions.isEmpty)
              Padding(
                padding: ResponsiveHelper.horizontalPadding(context),
                child: Container(
                  padding: ResponsiveHelper.padding(context, multiplier: 1.5),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceDark,
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.borderRadius(context, 12),
                    ),
                    border: Border.all(color: DesignTokens.borderDark),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.grey[600],
                        size: ResponsiveHelper.iconSize(context, 48),
                      ),
                      SizedBox(
                        height: ResponsiveHelper.verticalSpacing(context, 12),
                      ),
                      Text(
                        'No transactions found',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: ResponsiveHelper.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: ResponsiveHelper.horizontalPadding(context),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  itemBuilder:
                      (context, index) =>
                          _buildTransactionItem(transactions[index], context),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveHelper.symmetricPadding(
          context,
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color:
              isSelected ? DesignTokens.primaryColor : DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? DesignTokens.primaryColor
                    : DesignTokens.borderDark,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: ResponsiveHelper.fontSize(context, 12),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
