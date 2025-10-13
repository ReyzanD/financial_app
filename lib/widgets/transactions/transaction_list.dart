import 'package:flutter/material.dart';
import 'package:financial_app/widgets/transactions/transaction_card.dart';

class TransactionList extends StatelessWidget {
  final String selectedFilter;

  const TransactionList({super.key, required this.selectedFilter});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'id': '1',
        'name': 'Gaji Bulanan',
        'amount': 12500000,
        'category': 'Gaji',
        'type': 'income',
        'date': '2024-01-15',
        'location': 'PT. ABC Company',
        'notes': 'Gaji bulan Januari',
        'locationData': {
          'latitude': -6.2088,
          'longitude': 106.8456,
          'address': 'Jl. Sudirman No. 1, Jakarta Pusat',
          'placeId': 'ChIJdZOLiiCz0S0RgIJI',
        },
      },
      {
        'id': '2',
        'name': 'Belanja Bulanan',
        'amount': -750000,
        'category': 'Belanja',
        'type': 'expense',
        'date': '2024-01-14',
        'location': 'Supermarket XYZ',
        'notes': 'Belanja kebutuhan mingguan',
      },
      {
        'id': '3',
        'name': 'Bensin Motor',
        'amount': -50000,
        'category': 'Transportasi',
        'type': 'expense',
        'date': '2024-01-14',
        'location': 'SPBU Pertamina',
        'notes': 'Isi bensin full tank',
      },
      {
        'id': '4',
        'name': 'Bayar Listrik',
        'amount': -350000,
        'category': 'Tagihan',
        'type': 'expense',
        'date': '2024-01-13',
        'location': 'PLN',
        'notes': 'Tagihan listrik bulan Januari',
      },
      {
        'id': '5',
        'name': 'Freelance Project',
        'amount': 2500000,
        'category': 'Freelance',
        'type': 'income',
        'date': '2024-01-12',
        'location': 'Client ABC',
        'notes': 'Payment website development',
      },
    ];

    // Filter transactions based on selection
    final filteredTransactions =
        transactions.where((transaction) {
          if (selectedFilter == 'Semua') return true;
          if (selectedFilter == 'Pemasukan') {
            return transaction['type'] == 'income';
          }
          if (selectedFilter == 'Pengeluaran') {
            return transaction['type'] == 'expense';
          }
          // Add date filtering logic here
          return true;
        }).toList();

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTransactions.length,
        itemBuilder: (context, index) {
          final transaction = filteredTransactions[index];
          return TransactionCard(transaction: transaction);
        },
      ),
    );
  }
}
