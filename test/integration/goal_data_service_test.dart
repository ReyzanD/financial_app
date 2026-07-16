import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/models/goal_model.dart';

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
  late GoalDataService dataService;

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create tables needed by GoalDataService queries
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users_232143 (
        user_id_232143 TEXT PRIMARY KEY,
        full_name_232143 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_goals_232143 (
        goal_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        description_232143 TEXT,
        goal_type_232143 TEXT NOT NULL,
        target_amount_232143 REAL NOT NULL,
        current_amount_232143 REAL DEFAULT 0.00,
        start_date_232143 TEXT,
        target_date_232143 TEXT NOT NULL,
        is_completed_232143 INTEGER DEFAULT 0,
        completed_date_232143 TEXT,
        priority_232143 INTEGER DEFAULT 3,
        monthly_target_232143 REAL,
        auto_deduct_232143 INTEGER DEFAULT 0,
        deduct_percentage_232143 REAL,
        recommended_monthly_saving_232143 REAL,
        feasibility_score_232143 REAL,
        created_at_232143 TEXT,
        updated_at_232143 TEXT,
        progress_percentage_232143 REAL DEFAULT 0.00,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS goal_contributions_232143 (
        contribution_id_232143 TEXT PRIMARY KEY,
        goal_id_232143 TEXT NOT NULL,
        account_id_232143 TEXT,
        amount_232143 REAL NOT NULL,
        contributed_at_232143 TEXT,
        note_232143 TEXT,
        FOREIGN KEY (goal_id_232143) REFERENCES financial_goals_232143(goal_id_232143)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts_232143 (
        account_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        type_232143 TEXT,
        balance_232143 REAL DEFAULT 0,
        color_232143 TEXT,
        created_at_232143 TEXT,
        updated_at_232143 TEXT,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions_232143 (
        transaction_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        account_id_232143 TEXT,
        amount_232143 REAL NOT NULL,
        type_232143 TEXT NOT NULL,
        category_id_232143 TEXT,
        description_232143 TEXT,
        transaction_date_232143 TEXT,
        transaction_time_232143 TEXT,
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

    dbService = _TestDatabaseService(db);
    dataService = GoalDataService(
      dbService: dbService,
      authService: _FixedAuthService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('GoalDataService — integration (real SQLite)', () {
    test('addGoal → getGoals: round-trip preserves all fields', () async {
      final input = {
        'name': 'Liburan ke Bali',
        'description': 'Tabungan liburan keluarga',
        'goal_type': 'vacation',
        'target_amount': 5000000,
        'target_date': '2027-06-01',
        'priority': 4,
        'monthly_target': 500000,
      };

      final created = await dataService.addGoal(input);

      // Verify returned model
      expect(created.id, isNotEmpty);
      expect(created.name, 'Liburan ke Bali');
      expect(created.description, 'Tabungan liburan keluarga');
      expect(created.goalType, 'vacation');
      expect(created.targetAmount, 5000000);
      expect(created.currentAmount, 0.0);
      expect(created.priority, 4);
      expect(created.monthlyTarget, 500000);
      expect(created.isCompleted, false);

      // Read back via getGoals
      final goals = await dataService.getGoals();
      expect(goals.length, 1);

      final loaded = goals.first;
      expect(loaded.id, created.id);
      expect(loaded.name, 'Liburan ke Bali');
      expect(loaded.targetAmount, 5000000);
      expect(loaded.priority, 4);

      // Verify GoalModel.fromMap can parse the raw DB row
      final row = await db.query(
        'financial_goals_232143',
        where: 'goal_id_232143 = ?',
        whereArgs: [created.id],
      );
      expect(row.length, 1);
      expect(row.first['goal_id_232143'], created.id);
      expect(row.first['name_232143'], 'Liburan ke Bali');
      expect(row.first['target_amount_232143'], 5000000);

      final parsed = GoalModel.fromMap(row.first);
      expect(parsed.id, created.id);
      expect(parsed.name, 'Liburan ke Bali');
    });

    test('addGoal → updateGoal → getGoals: update round-trip', () async {
      final created = await dataService.addGoal({
        'name': 'Emergency Fund',
        'goal_type': 'emergency_fund',
        'target_amount': 10000000,
        'target_date': '2027-12-31',
        'priority': 5,
      });

      // Update name, target, and current amount
      final updated = await dataService.updateGoal(created.id, {
        'name': 'Dana Darurat',
        'target_amount': 15000000,
        'current_amount': 2500000,
      });

      expect(updated.name, 'Dana Darurat');
      expect(updated.targetAmount, 15000000);
      expect(updated.currentAmount, 2500000);

      // Verify via getGoals
      final goals = await dataService.getGoals();
      expect(goals.length, 1);
      expect(goals.first.name, 'Dana Darurat');
      expect(goals.first.targetAmount, 15000000);
      expect(goals.first.currentAmount, 2500000);
    });

    test('addGoal → deleteGoal returns true and removes it', () async {
      final created = await dataService.addGoal({
        'name': 'Mobil Baru',
        'goal_type': 'vehicle',
        'target_amount': 200000000,
        'target_date': '2028-01-01',
      });

      final deleted = await dataService.deleteGoal(created.id);
      expect(deleted, true);

      final goals = await dataService.getGoals();
      expect(goals.length, 0);
    });

    test('addGoalContribution without account records contribution', () async {
      final created = await dataService.addGoal({
        'name': 'HP Baru',
        'goal_type': 'other',
        'target_amount': 3000000,
        'target_date': '2026-12-01',
      });

      final result = await dataService.addGoalContribution(
        created.id,
        500000,
      );

      expect(result['success'], true);
      expect(result['new_amount'], 500000);
      expect(result['is_completed'], false);

      // Verify current_amount updated
      final goals = await dataService.getGoals();
      expect(goals.first.currentAmount, 500000);

      // Verify contribution recorded
      final contributions = await dataService.getGoalContributions(created.id);
      expect(contributions.length, 1);
      expect(contributions.first['amount_232143'], 500000);
    });

    test('addGoalContribution with account deducts balance and creates transaction',
        () async {
      // Insert an account with sufficient balance
      await db.insert('accounts_232143', {
        'account_id_232143': 'acc-savings-001',
        'user_id_232143': 'test-user-001',
        'name_232143': 'Tabungan',
        'type_232143': 'bank',
        'balance_232143': 2000000,
        'color_232143': '#4CAF50',
        'created_at_232143': DateTime.now().toIso8601String(),
      });

      final created = await dataService.addGoal({
        'name': 'Renovasi Rumah',
        'goal_type': 'other',
        'target_amount': 50000000,
        'target_date': '2027-06-01',
      });

      final result = await dataService.addGoalContribution(
        created.id,
        1000000,
        accountId: 'acc-savings-001',
        note: 'Transfer dari tabungan',
      );

      expect(result['success'], true);
      expect(result['new_amount'], 1000000);

      // Verify account balance deducted
      final accountResult = await db.query(
        'accounts_232143',
        where: 'account_id_232143 = ?',
        whereArgs: ['acc-savings-001'],
      );
      expect(accountResult.first['balance_232143'], 1000000);

      // Verify transaction recorded
      final txResult = await db.query('transactions_232143');
      expect(txResult.length, 1);
      expect(txResult.first['amount_232143'], 1000000);
      expect(txResult.first['type_232143'], 'expense');
    });

    test('getTotalGoalContributions sums across goals', () async {
      await dataService.addGoal({
        'name': 'Goal A',
        'goal_type': 'other',
        'target_amount': 1000000,
        'target_date': '2026-12-01',
      });

      await dataService.addGoal({
        'name': 'Goal B',
        'goal_type': 'other',
        'target_amount': 2000000,
        'target_date': '2027-06-01',
      });

      // Manually set current amounts to test summing
      final goals = await dataService.getGoals();
      await dataService.addGoalContribution(goals[0].id, 300000);
      await dataService.addGoalContribution(goals[1].id, 500000);

      final total = await dataService.getTotalGoalContributions();
      expect(total, 800000);
    });
  });
}
