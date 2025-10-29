import 'package:flutter/material.dart';
import 'package:financial_app/widgets/transactions/transaction_card.dart';
import 'package:financial_app/services/api_service.dart';

class TransactionList extends StatefulWidget {
  final String selectedFilter;

  const TransactionList({super.key, required this.selectedFilter});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void didUpdateWidget(TransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? type;
      if (widget.selectedFilter == 'Pemasukan') {
        type = 'income';
      } else if (widget.selectedFilter == 'Pengeluaran') {
        type = 'expense';
      }

      final transactions = await _apiService.getTransactions(
        type: type,
        limit: 50,
      );
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error - show empty state
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_transactions.isEmpty) {
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return TransactionCard(transaction: transaction);
        },
      ),
    );
  }
}
