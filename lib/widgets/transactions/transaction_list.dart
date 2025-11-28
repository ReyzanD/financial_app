import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/Screen/add_transaction_screen.dart';
import 'package:financial_app/widgets/transactions/transaction_card.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:financial_app/widgets/common/shimmer_loading.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/utils/page_transitions.dart';

class TransactionList extends StatefulWidget {
  final String selectedFilter;

  const TransactionList({super.key, required this.selectedFilter});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
  ) {
    if (widget.selectedFilter == 'Semua') {
      return transactions;
    } else if (widget.selectedFilter == 'Pemasukan') {
      return transactions.where((t) => t.type == 'income').toList();
    } else if (widget.selectedFilter == 'Pengeluaran') {
      return transactions.where((t) => t.type == 'expense').toList();
    } else if (widget.selectedFilter == 'Hari Ini') {
      final now = DateTime.now();
      return transactions
          .where(
            (t) =>
                t.transactionDate.year == now.year &&
                t.transactionDate.month == now.month &&
                t.transactionDate.day == now.day,
          )
          .toList();
    } else if (widget.selectedFilter == 'Minggu Ini') {
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
    } else if (widget.selectedFilter == 'Bulan Ini') {
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
            child: EmptyStates.serverError(() => appState.refreshData()),
          );
        }

        final filteredTransactions = _filterTransactions(appState.transactions);

        if (filteredTransactions.isEmpty) {
          return Expanded(
            child: EmptyStates.noTransactions(() async {
              final result = await Navigator.push(
                context,
                PageTransitions.slideUp(const AddTransactionScreen()),
              );
              if (result == true && context.mounted) {
                await appState.refreshData();
              }
            }),
          );
        }

        return Expanded(
          child: RefreshIndicator(
            onRefresh: () => appState.refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
              // Optimize rendering performance
              cacheExtent: 100,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
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
