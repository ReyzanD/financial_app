import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:financial_app/features/daad/presentation/screens/german_finance_screen.dart';
import 'package:financial_app/services/exchange_rate_service.dart';
import 'package:financial_app/services/data/exchange_rate_data_service.dart';
import 'package:financial_app/services/financial_advisor_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/network_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';

/// Minimal mock that overrides both services with canned data.
class _MockExchangeRateService extends ExchangeRateService {
  _MockExchangeRateService() : super(
    exchangeRateData: _DummyExchangeRateDataService(),
  );

  @override
  Future<double> getExchangeRate(String fromCode, String toCode) async {
    return 17500.0; // 1 EUR = 17500 IDR (fixed default)
  }
}

/// Dummy data service that avoids DB calls in tests.
class _DummyExchangeRateDataService extends ExchangeRateDataService {
  _DummyExchangeRateDataService() : super();
}

class _MockFinancialAdvisorService extends FinancialAdvisorService {
  _MockFinancialAdvisorService() : super(
    transactionData: TransactionDataService(),
  );

  @override
  Future<FiftyThirtyTwentyAnalysis> analyzeForPeriod({
    required DateTime start,
    required DateTime end,
  }) async {
    return FiftyThirtyTwentyAnalysis(
      monthlyIncome: 5000000,
      monthlyExpense: 3000000,
      savings: 2000000,
      needsActual: 2000000,
      wantsActual: 1000000,
      needsTarget: 2500000,
      wantsTarget: 1500000,
      savingsTarget: 1000000,
      needsPercent: 40.0,
      wantsPercent: 20.0,
      savingsPercent: 40.0,
      needsCategories: [],
      wantsCategories: [],
      needsGap: -500000,
      wantsGap: -500000,
      savingsGap: 1000000,
      goalRunRates: [],
    );
  }
}

Widget _buildTestApp() {
  return const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: GermanFinanceScreen(),
  );
}

void main() {
  setUp(() {
    if (!GetIt.instance.isRegistered<NetworkService>()) {
      GetIt.instance.registerLazySingleton<NetworkService>(
        () => NetworkService(),
      );
    }
    if (!GetIt.instance.isRegistered<ExchangeRateService>()) {
      GetIt.instance.registerLazySingleton<ExchangeRateService>(
        () => _MockExchangeRateService(),
      );
    }
    if (!GetIt.instance.isRegistered<FinancialAdvisorService>()) {
      GetIt.instance.registerLazySingleton<FinancialAdvisorService>(
        () => _MockFinancialAdvisorService(),
      );
    }
    if (!GetIt.instance.isRegistered<GoalDataService>()) {
      GetIt.instance.registerLazySingleton<GoalDataService>(
        () => GoalDataService(),
      );
    }
  });

  tearDown(() {
    // Don't reset GetIt completely — other tests may depend on registrations
  });

  group('GermanFinanceScreen', () {
    testWidgets('should render without crashing', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // AppBar title
      expect(find.text('Perencanaan Studi Jerman'), findsOneWidget);
    });

    testWidgets('should show Sperrkonto info after loading', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Sperrkonto card
      expect(find.text('Informasi Sperrkonto'), findsOneWidget);
      expect(find.text('Jumlah Dibutuhkan'), findsOneWidget);
      expect(find.text('Pencairan Bulanan'), findsOneWidget);
    });

    testWidgets('should show savings progress card', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Progres Tabungan Saya'), findsOneWidget);
      expect(find.text('Tabungan/Bulan'), findsOneWidget);
      expect(find.text('Estimasi Tercapai'), findsOneWidget);
    });

    testWidgets('should show EUR/IDR converter', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Konverter EUR/IDR'), findsOneWidget);
      expect(find.text('Euro (EUR)'), findsOneWidget);
      expect(find.text('Rupiah (IDR)'), findsOneWidget);
    });

    testWidgets('should show quick converter chips', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('€992'), findsOneWidget);
      expect(find.text('€11.904'), findsOneWidget);
    });

    testWidgets('should show Buat Goal button', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Buat Goal Sperrkonto'), findsOneWidget);
    });

    testWidgets('should show info banner', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Banner text contains key info about Sperrkonto
      expect(
        find.textContaining('Sperrkonto'),
        findsWidgets,
      );
    });
  });
}
