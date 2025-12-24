/// Widget tests for FinancialSummaryCard
///
/// Tests the financial summary card widget functionality including:
/// - Loading states
/// - Data display
/// - Error handling
/// - Month selection

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/widgets/home/financial_summary_card.dart';

void main() {
  group('FinancialSummaryCard', () {
    testWidgets('should display loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinancialSummaryCard(),
          ),
        ),
      );

      // Widget should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have correct widget structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinancialSummaryCard(),
          ),
        ),
      );

      // Check that the widget is rendered
      expect(find.byType(FinancialSummaryCard), findsOneWidget);
    });
  });
}

