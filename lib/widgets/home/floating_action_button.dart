import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/state/app_state.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';

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
        if (!context.mounted) return;
        if (result == true) {
          // Trigger data refresh using AppState which has DataService
          final appState = Provider.of<AppState>(context, listen: false);
          await appState.refreshData(forceRefresh: true);

          if (!context.mounted) return;
          // Show success feedback
          ErrorHandlerService.showSuccessSnackbar(
            context,
            'Dashboard diperbarui',
          );
        }
      },
      backgroundColor: DesignTokens.primaryColor,
      child: const Icon(Iconsax.add, color: Colors.white),
    );
  }
}
