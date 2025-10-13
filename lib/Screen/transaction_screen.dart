import 'package:flutter/material.dart';
import 'package:financial_app/widgets/transactions/transaction_header.dart';
import 'package:financial_app/widgets/transactions/transaction_filters.dart';
import 'package:financial_app/widgets/transactions/transaction_list.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const TransactionHeader(),

            // Filter Chips
            TransactionFilters(
              selectedFilter: _selectedFilter,
              onFilterChanged: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),

            // Transactions List
            TransactionList(selectedFilter: _selectedFilter),
          ],
        ),
      ),
    );
  }
}
