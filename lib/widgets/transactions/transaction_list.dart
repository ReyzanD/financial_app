import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/Screen/add_transaction_screen.dart';
import 'package:financial_app/widgets/transactions/transaction_card.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/widgets/common/shimmer_loading.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/utils/page_transitions.dart';
import 'package:financial_app/services/search_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class TransactionList extends StatefulWidget {
  final String selectedFilter;
  final String searchQuery;

  const TransactionList({
    super.key,
    required this.selectedFilter,
    this.searchQuery = '',
  });

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final SearchService _searchService = SearchService();
  List<TransactionModel> _searchedTransactions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.searchQuery.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void didUpdateWidget(TransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      if (widget.searchQuery.isNotEmpty) {
        _performSearch();
      } else {
        setState(() {
          _searchedTransactions = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _performSearch() async {
    if (widget.searchQuery.isEmpty) {
      setState(() {
        _searchedTransactions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Determine type filter from selectedFilter
      String? typeFilter;
      DateTime? startDate;
      DateTime? endDate;

      final l10n = AppLocalizations.of(context);
      if (widget.selectedFilter == (l10n?.income ?? 'Pemasukan')) {
        typeFilter = 'income';
      } else if (widget.selectedFilter == (l10n?.expense ?? 'Pengeluaran')) {
        typeFilter = 'expense';
      } else if (widget.selectedFilter == (l10n?.today ?? 'Hari Ini')) {
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (widget.selectedFilter == (l10n?.this_week ?? 'Minggu Ini')) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        startDate = today.subtract(Duration(days: today.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
      } else if (widget.selectedFilter == (l10n?.this_month ?? 'Bulan Ini')) {
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }

      final results = await _searchService.searchTransactions(
        query: widget.searchQuery,
        type: typeFilter,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _searchedTransactions = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
  ) {
    final l10n = AppLocalizations.of(context);
    if (widget.selectedFilter == (l10n?.all ?? 'Semua')) {
      return transactions;
    } else if (widget.selectedFilter == (l10n?.income ?? 'Pemasukan')) {
      return transactions.where((t) => t.type == 'income').toList();
    } else if (widget.selectedFilter == (l10n?.expense ?? 'Pengeluaran')) {
      return transactions.where((t) => t.type == 'expense').toList();
    } else if (widget.selectedFilter == (l10n?.today ?? 'Hari Ini')) {
      final now = DateTime.now();
      return transactions
          .where(
            (t) =>
                t.transactionDate.year == now.year &&
                t.transactionDate.month == now.month &&
                t.transactionDate.day == now.day,
          )
          .toList();
    } else if (widget.selectedFilter == (l10n?.this_week ?? 'Minggu Ini')) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      return transactions
          .where(
            (t) =>
                !t.transactionDate.isBefore(startOfWeek) &&
                t.transactionDate.isBefore(endOfWeek),
          )
          .toList();
    } else if (widget.selectedFilter == (l10n?.this_month ?? 'Bulan Ini')) {
      final now = DateTime.now();
      return transactions
          .where(
            (t) =>
                t.transactionDate.year == now.year &&
                t.transactionDate.month == now.month,
          )
          .toList();
    }
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Expanded(child: TransactionShimmer());
        }

        if (appState.error != null) {
          return Expanded(
            child: EmptyStates.serverError(
              () => appState.refreshData(),
              context,
            ),
          );
        }

        // Use searched transactions if search query exists, otherwise use filtered transactions
        final transactionsToShow =
            widget.searchQuery.isNotEmpty
                ? _searchedTransactions
                : _filterTransactions(appState.transactions);

        if (_isSearching) {
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
            ),
          );
        }

        if (transactionsToShow.isEmpty) {
          return Expanded(
            child: EmptyStates.noTransactions(() async {
              final result = await Navigator.push(
                context,
                PageTransitions.slideUp(const AddTransactionScreen()),
              );
              if (result == true && context.mounted) {
                await appState.refreshData();
              }
            }, context),
          );
        }

        return Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await appState.refreshData();
              if (widget.searchQuery.isNotEmpty) {
                await _performSearch();
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactionsToShow.length,
              // Optimize rendering performance
              cacheExtent: 100,
              itemBuilder: (context, index) {
                final transaction = transactionsToShow[index];
                final transactionMap = {
                  'id': transaction.id, // Required for delete and edit
                  'amount': transaction.amount,
                  'type': transaction.type,
                  'description': transaction.description,
                  'category': transaction.categoryName,
                  'category_id': transaction.categoryId, // Required for edit
                  'payment_method':
                      transaction.paymentMethod, // Required for edit
                  'date': transaction.transactionDate.toIso8601String(),
                  'location': '',
                  'category_color': transaction.categoryColor,
                };
                return StaggeredListAnimation(
                  index: index,
                  child: TransactionCard(
                    transaction: transactionMap,
                    onDeleted: () => appState.refreshData(forceRefresh: true),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
