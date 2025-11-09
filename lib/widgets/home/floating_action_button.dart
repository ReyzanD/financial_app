import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/Screen/add_transaction_screen.dart';
import 'package:financial_app/Screen/home_screen.dart';

class HomeFloatingActionButton extends StatelessWidget {
  const HomeFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
        );

        // If transaction was added successfully, refresh the dashboard
        if (result == true) {
          // Trigger a refresh by rebuilding the home screen
          // The home screen will handle refreshing its data
          // For now, we'll just show a success message
          // In a real app, you might want to implement a more sophisticated refresh mechanism
        }
      },
      backgroundColor: const Color(0xFF8B5FBF),
      child: const Icon(Iconsax.add, color: Colors.white),
    );
  }
}
