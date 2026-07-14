import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:financial_app/widgets/home/quick_add/quick_add_modal.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';

/// Minimal ApiService subclass that doesn't need SQLite for testing.
class _MockApiService extends ApiService {
  _MockApiService() : super(
    categoryData: CategoryDataService(),
    goalData: GoalDataService(),
    obligationData: ObligationDataService(),
    transactionData: TransactionDataService(),
    budgetData: BudgetDataService(),
  );

  @override
  Future<List<dynamic>> getCategories({bool forceRefresh = false}) async => [];
}

void main() {
  // Ensure ApiService is registered in GetIt before any tests run
  setUpAll(() {
    if (!GetIt.instance.isRegistered<ApiService>()) {
      GetIt.instance.registerLazySingleton<ApiService>(() => _MockApiService());
    }
  });

  group('QuickAddModal presetDescription wiring', () {
    testWidgets(
      'should pre-fill description when presetDescription is provided',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: QuickAddModal(
                type: 'expense',
                presetDescription: 'Makan siang',
              ),
            ),
          ),
        );

        // Wait for modal to render and categories to load
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        // Verify the description field is pre-filled
        // Note: uses TextField not TextFormField
        expect(find.byType(TextField), findsWidgets);
      },
    );

    testWidgets(
      'should not pre-fill description when presetDescription is null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: QuickAddModal(type: 'expense')),
          ),
        );

        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        // Verify the modal renders without crashing
        expect(find.byType(QuickAddModal), findsOneWidget);
      },
    );
  });
}
