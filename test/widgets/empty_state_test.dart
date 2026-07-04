import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Iconsax.home,
              title: 'No Data',
              subtitle: 'Add some data to get started',
            ),
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Add some data to get started'), findsOneWidget);
      expect(find.byIcon(Iconsax.home), findsOneWidget);
    });

    testWidgets('renders with action button when actionText is provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Iconsax.home,
              title: 'No Data',
              subtitle: 'Add some data',
              actionText: 'Add Data',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add Data'), findsOneWidget);
    });

    testWidgets('does not render action button when actionText is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Iconsax.home,
              title: 'No Data',
              subtitle: 'Add some data',
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('calls onAction when button is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Iconsax.home,
              title: 'No Data',
              subtitle: 'Add some data',
              actionText: 'Add Data',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Data'));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('applies custom icon color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Iconsax.home,
              title: 'No Data',
              subtitle: 'Add some data',
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Iconsax.home));
      expect(icon.color, Colors.red);
    });
  });
}
