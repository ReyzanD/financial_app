import 'package:financial_app/Screen/goals_screen.dart';
import 'package:flutter/material.dart';
import 'package:financial_app/Screen/transaction_screen.dart';
import 'package:financial_app/Screen/analytics_screen.dart';

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
}
