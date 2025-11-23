import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/Screen/add_transaction_screen.dart';
import 'package:financial_app/Screen/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/data_service.dart';

class HomeFloatingActionButton extends StatelessWidget {
  const HomeFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'home_fab',
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
        );

        // If transaction was added successfully, refresh the dashboard
        if (result == true && context.mounted) {
          // Trigger data refresh using DataService
          final dataService = Provider.of<DataService>(context, listen: false);
          await dataService.refreshAllData();

          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dashboard diperbarui'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      backgroundColor: const Color(0xFF8B5FBF),
      child: const Icon(Iconsax.add, color: Colors.white),
    );
  }
}
