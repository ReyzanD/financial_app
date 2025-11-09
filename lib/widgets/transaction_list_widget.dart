import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../models/transaction_model.dart';

class TransactionListWidget extends StatelessWidget {
  const TransactionListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${appState.error}'),
                ElevatedButton(
                  onPressed: () => appState.refreshData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final transactions = appState.transactions;
        if (transactions.isEmpty) {
          return const Center(child: Text('No transactions found'));
        }

        return RefreshIndicator(
          onRefresh: () => appState.refreshData(),
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionListItem(transaction: transaction);
            },
          ),
        );
      },
    );
  }
}

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('dd MMM yyyy');

    Color amountColor =
        transaction.type == 'income' ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(
              int.parse(transaction.categoryColor.replaceAll('#', '0xFF')),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.category, color: Colors.white),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${transaction.categoryName} • ${dateFormat.format(transaction.transactionDate)}',
        ),
        trailing: Text(
          numberFormat.format(transaction.amount),
          style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
