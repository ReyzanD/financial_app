import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/widgets/transactions/transaction_card.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/models/transaction_model.dart';

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
    }
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Expanded(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (appState.error != null) {
          return Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${appState.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => appState.refreshData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredTransactions = _filterTransactions(appState.transactions);

        if (filteredTransactions.isEmpty) {
          return Expanded(
            child: Center(
              child: Text(
                'Belum ada transaksi',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          );
        }

        return Expanded(
          child: RefreshIndicator(
            onRefresh: () => appState.refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredTransactions.length,
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
                return TransactionCard(
                  transaction: transactionMap,
                  onDeleted: () => appState.refreshData(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
