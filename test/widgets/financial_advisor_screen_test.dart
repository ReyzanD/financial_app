import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:financial_app/features/financial_advisor/presentation/screens/financial_advisor_screen.dart';
import 'package:financial_app/services/financial_advisor_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/network_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';

/// Minimal mock that extends FinancialAdvisorService but overrides every
/// method that touches the database — returns canned data instead.
class _MockFinancialAdvisorService extends FinancialAdvisorService {
  _MockFinancialAdvisorService()
    : super(transactionData: TransactionDataService());

  @override
  Future<FiftyThirtyTwentyAnalysis> analyzeForPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    return _createMockAnalysis();
  }

  @override
  Future<FiftyThirtyTwentyAnalysis> analyzeCurrentMonth() async {
    return _createMockAnalysis();
  }

  @override
  Future<List<FiftyThirtyTwentyAnalysis>> analyzeMultiMonth(int count) async {
    return List.generate(count, (_) => _createMockAnalysis());
  }

  FiftyThirtyTwentyAnalysis _createMockAnalysis() {
    return FiftyThirtyTwentyAnalysis(
      monthlyIncome: 10000000,
      monthlyExpense: 6000000,
      savings: 4000000,
      needsActual: 3500000,
      wantsActual: 2500000,
      needsTarget: 5000000,
      wantsTarget: 3000000,
      savingsTarget: 2000000,
      needsPercent: 35.0,
      wantsPercent: 25.0,
      savingsPercent: 40.0,
      needsCategories: [
        const CategoryBreakdown(
          name: 'Makanan & Minuman',
          amount: 2000000,
          percentOfIncome: 20.0,
        ),
        const CategoryBreakdown(
          name: 'Transportasi',
          amount: 1000000,
          percentOfIncome: 10.0,
        ),
        const CategoryBreakdown(
          name: 'Listrik',
          amount: 500000,
          percentOfIncome: 5.0,
        ),
      ],
      wantsCategories: [
        const CategoryBreakdown(
          name: 'Hiburan',
          amount: 1500000,
          percentOfIncome: 15.0,
        ),
        const CategoryBreakdown(
          name: 'Belanja',
          amount: 1000000,
          percentOfIncome: 10.0,
        ),
      ],
      needsGap: -1500000,
      wantsGap: -500000,
      savingsGap: -2000000,
      goalRunRates: [
        const GoalRunRate(
          name: 'Dana Darurat',
          targetAmount: 50000000,
          currentAmount: 10000000,
          monthlyContribution: 500000,
          progressPercent: 20.0,
          monthsToGoal: 80,
        ),
      ],
    );
  }
}

Widget _buildTestApp() {
  return const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: FinancialAdvisorScreen(),
  );
}

void main() {
  setUp(() {
    if (!GetIt.instance.isRegistered<NetworkService>()) {
      GetIt.instance.registerLazySingleton<NetworkService>(
        () => NetworkService(),
      );
    }
    if (!GetIt.instance.isRegistered<FinancialAdvisorService>()) {
      GetIt.instance.registerLazySingleton<FinancialAdvisorService>(
        () => _MockFinancialAdvisorService(),
      );
    }
  });

  tearDown(() {
    // Don't reset GetIt completely — other tests may depend on registrations
  });

  group('FinancialAdvisorScreen', () {
    testWidgets('should render without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // AppBar title should be present
      expect(find.text('Penasihat Keuangan'), findsOneWidget);
    });

    testWidgets('should show summary card after loading', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Summary card labels — "Tabungan" appears in summary card AND 50/30/20 card
      expect(find.text('Ringkasan Bulan Ini'), findsOneWidget);
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Tabungan'), findsWidgets);
    });

    testWidgets('should display formatted income value', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Rp 10.000.000 formatted
      expect(find.textContaining('Rp'), findsWidgets);
    });

    testWidgets('should show 50/30/20 rule card', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Aturan 50/30/20'), findsOneWidget);
      expect(find.text('Kebutuhan'), findsWidgets); // multiple occurrences
      expect(find.text('Keinginan'), findsWidgets);
    });

    testWidgets('should show period selector with two options', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Bulan Ini'), findsOneWidget);
      expect(find.text('Bulan Lalu'), findsOneWidget);
    });

    testWidgets('should show assessment card', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Penilaian'), findsOneWidget);
    });

    testWidgets('should show category breakdowns', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Needs and wants sections
      expect(find.text('Kebutuhan (50%)'), findsOneWidget);
      expect(find.text('Keinginan (30%)'), findsOneWidget);
    });

    testWidgets('should show goals section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Progres Goals'), findsOneWidget);
      expect(find.text('Dana Darurat'), findsOneWidget);
    });

    testWidgets('should show savings suggestions', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Savings suggestions section
      expect(find.text('Cara Hemat'), findsOneWidget);
    });

    testWidgets('should show 3-month trend section', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Tren 3 Bulan'), findsOneWidget);
    });
  });
}
