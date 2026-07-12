import 'package:flutter/material.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/common/insufficient_balance_dialog.dart';

/// Shared helper for checking whether an expense would leave the balance
/// below the minimum threshold (Rp 25,000).
///
/// Replaces the previously duplicated logic in add_transaction_screen.dart
/// and quick_add_modal.dart.
class BalanceCheckHelper {
  static const double minimumBalance = 25000.0;

  /// Checks if the expense can be afforded given the current balance.
  ///
  /// [summary] is the raw financial summary map (returned by either
  /// `ApiService.getFinancialSummary()` or `TransactionDataService.getFinancialSummary()`).
  ///
  /// Returns `true` if the balance is sufficient (or if the check fails).
  /// Returns `false` if the balance would drop below [minimumBalance] —
  /// and shows an [InsufficientBalanceDialog] explaining the shortfall.
  static Future<bool> checkBalanceBeforeExpense({
    required BuildContext context,
    required double expenseAmount,
    required Map<String, dynamic> summary,
  }) async {
    try {
      final summaries = summary['summary'] as Map<String, dynamic>?;

      if (summaries == null) return true; // Allow if we can't check

      final income =
          (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;
      final expense =
          (summaries['expense'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;
      final currentBalance = income - expense;
      final newBalance = currentBalance - expenseAmount;

      if (newBalance < minimumBalance) {
        if (!context.mounted) return false;
        await InsufficientBalanceDialog.show(
          context: context,
          currentBalance: currentBalance,
          expenseAmount: expenseAmount,
          minimumBalance: minimumBalance,
        );
        return false; // Block the transaction
      }

      return true; // Balance is fine, proceed
    } catch (e) {
      LoggerService.error('Error checking balance', error: e);
      return true; // Allow transaction if check fails
    }
  }
}
