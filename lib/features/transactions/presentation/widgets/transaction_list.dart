import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:financial_app/features/transactions/domain/entities/transaction_entity.dart';
import 'package:financial_app/widgets/transactions/transaction_card.dart';
import 'package:financial_app/widgets/common/shimmer_loading.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/utils/page_transitions.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/services/search_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Internal model for grouped list — either a date header or a transaction item
class _DateHeader {
  final String label;
  final String subtitle;
  const _DateHeader(this.label, this.subtitle);
}

class _TransactionItem {
  final TransactionEntity transaction;
  final int staggerIndex;
  const _TransactionItem(this.transaction, this.staggerIndex);
}

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
  List<TransactionEntity> _searchedTransactions = [];
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
        _searchedTransactions = results
            .map((t) => TransactionEntity(
                  id: t.id,
                  type: t.type,
                  amount: t.amount,
                  categoryId: t.categoryId,
                  categoryName: t.categoryName,
                  description: t.description,
                  transactionDate: t.transactionDate,
                ))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// Build a grouped list where each date gets a section header.
  /// Returns a flat list of [_DateHeader] and [_TransactionItem] objects.
  List<Object> _buildGroupedItems(List<TransactionEntity> transactions) {
    if (transactions.isEmpty) return const [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Group by date key (YYYY-MM-DD) preserving sort order
    final grouped = <String, List<TransactionEntity>>{};
    for (final t in transactions) {
      final d = t.transactionDate;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(t);
    }

    // Sort groups newest-first
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final items = <Object>[];
    int staggerIndex = 0;

    for (final key in sortedKeys) {
      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      String label;
      String subtitle;
      if (date == today) {
        label = 'Hari Ini';
        subtitle = '';
      } else if (date == yesterday) {
        label = 'Kemarin';
        subtitle = '';
      } else {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
        ];
        const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        label = '${date.day} ${months[date.month - 1]} ${date.year}';
        subtitle = dayNames[date.weekday - 1];
      }

      items.add(_DateHeader(label, subtitle));
      for (final transaction in grouped[key]!) {
        items.add(_TransactionItem(transaction, staggerIndex));
        staggerIndex++;
      }
    }

    return items;
  }

  /// Convert a TransactionEntity to the Map format expected by TransactionCard
  Map<String, dynamic> _toTransactionMap(TransactionEntity t) {
    return {
      'id': t.id,
      'amount': t.amount,
      'type': t.type,
      'description': t.description,
      'category': t.categoryName,
      'category_id': t.categoryId,
      'payment_method': 'cash',
      'date': t.transactionDate.toIso8601String(),
      'location': t.locationName ?? '',
      'category_color': 0xFF8B5FBF,
    };
  }

  /// Build a date section header widget
  Widget _buildDateHeader(BuildContext context, _DateHeader header) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.horizontalSpacing(context, 16),
        ResponsiveHelper.verticalSpacing(context, 16),
        ResponsiveHelper.horizontalSpacing(context, 16),
        ResponsiveHelper.verticalSpacing(context, 8),
      ),
      child: Row(
        children: [
          Text(
            header.label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: ResponsiveHelper.fontSize(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (header.subtitle.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: DesignTokens.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                header.subtitle,
                style: GoogleFonts.poppins(
                  color: DesignTokens.primaryColor,
                  fontSize: ResponsiveHelper.fontSize(context, 10),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const Spacer(),
          // Thin accent line
          Container(
            height: 1,
            width: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.primaryColor.withValues(alpha: 0.3),
                  DesignTokens.primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TransactionEntity> _filterTransactions(
    List<TransactionEntity> transactions,
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
    return Consumer<TransactionController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Expanded(child: TransactionShimmer());
        }

        if (controller.error != null) {
          return Expanded(
            child: EmptyStates.serverError(
              () => controller.loadTransactions(),
              context,
            ),
          );
        }

        // Use searched transactions if search query exists, otherwise use filtered transactions
        final transactionsToShow =
            widget.searchQuery.isNotEmpty
                ? _searchedTransactions
                : _filterTransactions(controller.transactions);

        if (_isSearching) {
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryColor),
            ),
          );
        }

        if (transactionsToShow.isEmpty) {
          return Expanded(
            child: EmptyStates.noTransactions(() async {
              final result = await Navigator.pushNamed(
                context,
                '/add-transaction',
              );
              if (result == true && context.mounted) {
                await controller.loadTransactions();
              }
            }, context),
          );
        }

        // Build grouped list with date headers
        final groupedItems = _buildGroupedItems(transactionsToShow);

        return Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await controller.loadTransactions();
              if (widget.searchQuery.isNotEmpty) {
                await _performSearch();
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: groupedItems.length,
              cacheExtent: 100,
              itemBuilder: (context, index) {
                final item = groupedItems[index];
                if (item is _DateHeader) {
                  return _buildDateHeader(context, item);
                }
                final wrapper = item as _TransactionItem;
                return StaggeredListAnimation(
                  index: wrapper.staggerIndex,
                  child: TransactionCard(
                    transaction: _toTransactionMap(wrapper.transaction),
                    onDeleted: () => controller.loadTransactions(),
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
