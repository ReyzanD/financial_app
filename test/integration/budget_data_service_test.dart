import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:financial_app/services/data/budget_data_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/models/budget_model.dart';

/// A [LocalDatabaseService] that uses an in-memory SQLite database provided
/// by the test, so we can exercise the real data-service code paths without
/// hitting the file system.
class _TestDatabaseService extends LocalDatabaseService {
  final Database testDb;

  _TestDatabaseService(this.testDb) : super.test();

  @override
  Future<Database> get database async => testDb;
}

/// A [LocalAuthService] that always returns the same fixed user ID.
class _FixedAuthService extends LocalAuthService {
  @override
  Future<String?> getCurrentUserId() async => 'test-user-001';
}

void main() {
  late Database db;
  late _TestDatabaseService dbService;
  late BudgetDataService dataService;

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create tables needed by BudgetDataService queries
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users_232143 (
        user_id_232143 TEXT PRIMARY KEY,
        full_name_232143 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories_232143 (
        category_id_232143 TEXT PRIMARY KEY,
        name_232143 TEXT NOT NULL,
        type_232143 TEXT,
        color_232143 TEXT,
        icon_232143 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets_232143 (
        budget_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        category_id_232143 TEXT,
        amount_232143 REAL NOT NULL,
        period_232143 TEXT NOT NULL,
        period_start_232143 TEXT NOT NULL,
        period_end_232143 TEXT NOT NULL,
        spent_amount_232143 REAL DEFAULT 0.00,
        remaining_amount_232143 REAL DEFAULT 0.00,
        rollover_enabled_232143 INTEGER DEFAULT 0,
        alert_threshold_232143 INTEGER DEFAULT 80,
        is_active_232143 INTEGER DEFAULT 1,
        recommendation_reason_232143 TEXT,
        created_at_232143 TEXT,
        updated_at_232143 TEXT,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143)
      )
    ''');

    // Insert test user
    await db.insert('users_232143', {
      'user_id_232143': 'test-user-001',
      'full_name_232143': 'Test User',
    });

    // Insert test category
    await db.insert('categories_232143', {
      'category_id_232143': 'cat-food-001',
      'name_232143': 'Makanan & Minuman',
      'type_232143': 'expense',
      'color_232143': '#FF6B6B',
      'icon_232143': 'food',
    });

    dbService = _TestDatabaseService(db);
    dataService = BudgetDataService(
      dbService: dbService,
      authService: _FixedAuthService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('BudgetDataService — integration (real SQLite)', () {
    test('addBudget → getBudgets: round-trip preserves all fields', () async {
      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      final input = {
        'category_id': 'cat-food-001',
        'amount': 1000000,
        'period': 'monthly',
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'rollover_enabled': false,
        'alert_threshold': 80,
        'is_active': true,
      };

      final created = await dataService.addBudget(input);

      // Verify the returned model
      expect(created.id, isNotEmpty);
      expect(created.categoryId, 'cat-food-001');
      expect(created.amount, 1000000);
      expect(created.spent, 0.0);
      expect(created.remaining, 1000000);
      expect(created.period, 'monthly');
      expect(created.rolloverEnabled, false);
      expect(created.alertThreshold, 80);
      expect(created.isActive, true);

      // Read back via getBudgets
      final budgets = await dataService.getBudgets(activeOnly: true);
      expect(budgets.length, 1);

      final loaded = budgets.first;
      expect(loaded.id, created.id);
      expect(loaded.categoryId, 'cat-food-001');
      expect(loaded.amount, 1000000);
      expect(loaded.spent, 0.0);
      expect(loaded.remaining, 1000000);

      // Verify BudgetModel.fromMap can parse raw DB row
      final row = await db.query(
        'budgets_232143',
        where: 'budget_id_232143 = ?',
        whereArgs: [created.id],
      );
      expect(row.length, 1);
      expect(row.first['budget_id_232143'], created.id);
      expect(row.first['amount_232143'], 1000000);
      expect(row.first['spent_amount_232143'], 0.0);

      final parsed = BudgetModel.fromMap(row.first);
      expect(parsed.id, created.id);
      expect(parsed.amount, 1000000);
      expect(parsed.spent, 0.0);
    });

    test('addBudget → getBudgets with activeOnly=false includes inactive',
        () async {
      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      // Add active budget
      await dataService.addBudget({
        'category_id': 'cat-food-001',
        'amount': 500000,
        'period': 'monthly',
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'is_active': true,
      });

      // Add inactive budget
      await dataService.addBudget({
        'category_id': 'cat-food-001',
        'amount': 300000,
        'period': 'monthly',
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'is_active': false,
      });

      final activeOnly = await dataService.getBudgets(activeOnly: true);
      expect(activeOnly.length, 1);

      final all = await dataService.getBudgets(activeOnly: false);
      expect(all.length, 2);
    });

    test('addBudget → updateBudget → getBudgets: update round-trip', () async {
      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      final created = await dataService.addBudget({
        'category_id': 'cat-food-001',
        'amount': 1000000,
        'period': 'monthly',
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'is_active': true,
      });

      // Update amount
      final updated = await dataService.updateBudget(created.id, {
        'amount': 2000000,
      });

      expect(updated, isNotNull);
      expect(updated!.amount, 2000000);

      // Verify via getBudgets
      final budgets = await dataService.getBudgets(activeOnly: true);
      expect(budgets.length, 1);
      expect(budgets.first.amount, 2000000);
    });

    test('addBudget → deleteBudget returns true and removes it', () async {
      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      final created = await dataService.addBudget({
        'category_id': 'cat-food-001',
        'amount': 500000,
        'period': 'monthly',
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'is_active': true,
      });

      final deleted = await dataService.deleteBudget(created.id);
      expect(deleted, true);

      final budgets = await dataService.getBudgets(activeOnly: false);
      expect(budgets.length, 0);
    });

    test('updateBudgetForExpense updates spent/remaining amounts', () async {
      final now = DateTime.now();
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 0);

      await dataService.addBudget({
        'category_id': 'cat-food-001',
        'amount': 1000000,
        'period': 'monthly',
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'is_active': true,
      });

      // Simulate expense
      final updated = await dataService.updateBudgetForExpense(
        categoryId: 'cat-food-001',
        amount: 50000,
        transactionDate: DateTime(now.year, now.month, 15),
      );
      expect(updated, true);

      // Verify budget updated
      final budgets = await dataService.getBudgets(activeOnly: true);
      expect(budgets.length, 1);
      expect(budgets.first.spent, 50000);
      expect(budgets.first.remaining, 950000);
    });
  });
}
