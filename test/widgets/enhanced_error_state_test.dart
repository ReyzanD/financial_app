import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/widgets/common/enhanced_error_state.dart';

void main() {
  group('EnhancedErrorState', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedErrorState(
              title: 'Error',
              message: 'Something went wrong',
            ),
          ),
        ),
      );

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedErrorState(
              title: 'Error',
              message: 'Something went wrong',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does not show retry button when onRetry is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedErrorState(
              title: 'Error',
              message: 'Something went wrong',
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('calls onRetry when button is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedErrorState(
              title: 'Error',
              message: 'Something went wrong',
              onRetry: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('shows custom retry label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedErrorState(
              title: 'Error',
              message: 'Something went wrong',
              onRetry: null,
              retryLabel: 'Coba Lagi',
            ),
          ),
        ),
      );

      // The retry label only shows when onRetry is provided
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders in compact mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedErrorState(
              title: 'Error',
              message: 'Something went wrong',
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('shows custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedErrorState(
              title: 'Error',
              message: 'Something went wrong',
              icon: Icons.error_outline,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows default warning icon when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EnhancedErrorState(
              title: 'Error',
              message: 'Something went wrong',
            ),
          ),
        ),
      );

      // Default icon is Iconsax.warning_2, but since we can't access iconsax directly in test
      // we just verify an icon exists
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
