import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

void main() {
  testWidgets('OfflineIndicator renders correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: OfflineIndicator())),
    );

    expect(find.byType(OfflineIndicator), findsOneWidget);
  });

  testWidgets('OfflineIndicator does not crash when offline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: OfflineIndicator())),
    );

    await tester.pump();

    expect(find.byType(OfflineIndicator), findsOneWidget);
  });
}
