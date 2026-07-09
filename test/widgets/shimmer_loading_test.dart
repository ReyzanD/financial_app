import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/widgets/common/shimmer_loading.dart';

void main() {
  group('ShimmerLoading', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ShimmerLoading())),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
    });
  });

  group('TransactionShimmer', () {
    testWidgets('renders list of shimmer items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TransactionShimmer())),
      );

      expect(find.byType(TransactionShimmer), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('CardShimmer', () {
    testWidgets('renders with default height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CardShimmer())),
      );

      expect(find.byType(CardShimmer), findsOneWidget);
    });

    testWidgets('renders with custom height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CardShimmer(height: 200))),
      );

      expect(find.byType(CardShimmer), findsOneWidget);
    });
  });

  group('CardListShimmer', () {
    testWidgets('renders with default item count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(height: 1000, width: 500, child: CardListShimmer()),
        ),
      );

      expect(find.byType(CardListShimmer), findsOneWidget);
      expect(find.byType(CardShimmer), findsWidgets);
    });

    testWidgets('renders with custom item count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            height: 1000,
            width: 500,
            child: CardListShimmer(itemCount: 3),
          ),
        ),
      );

      expect(find.byType(CardShimmer), findsNWidgets(3));
    });

    testWidgets('renders with custom card height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CardListShimmer(cardHeight: 150)),
      );

      expect(find.byType(CardListShimmer), findsOneWidget);
    });
  });

  group('SummaryCardShimmer', () {
    testWidgets('renders shimmer summary cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SummaryCardShimmer())),
      );

      expect(find.byType(SummaryCardShimmer), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });
  });

  group('ShimmerBox', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ShimmerBox(width: 100, height: 50)),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('renders with custom border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerBox(
              width: 100,
              height: 50,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
    });
  });
}
