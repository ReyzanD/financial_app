import 'package:financial_app/features/goals/presentation/screens/goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:financial_app/features/transactions/presentation/screens/transaction_screen.dart';
import 'package:financial_app/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:financial_app/features/obligations/presentation/screens/financial_obligations_screen.dart';

class TabPlaceholders {
  static Widget buildTransactionsTab() {
    return const TransactionsScreen();
  }

  static Widget buildGoalsTab() {
    return const GoalsScreen();
  }

  static Widget buildAnalyticsTab() {
    return const AnalyticsScreen();
  }

  static Widget buildBillsTab() {
    return const FinancialObligationsScreen();
  }
}
