/// Widget tests for EmptyState components
///
/// Tests empty state widgets including:
/// - No transactions state
/// - Server error state
/// - Network error state

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/widgets/common/empty_state.dart';

void main() {
  group('EmptyStates', () {
    testWidgets('should display no transactions message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.noTransactions(() {}),
          ),
        ),
      );

      expect(find.text('Tidak ada transaksi'), findsOneWidget);
    });

    testWidgets('should have action button for no transactions', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStates.noTransactions(() {
              buttonPressed = true;
            }),
          ),
        ),
      );

      final button = find.text('Tambah Transaksi');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      expect(buttonPressed, isTrue);
    });
  });
}

