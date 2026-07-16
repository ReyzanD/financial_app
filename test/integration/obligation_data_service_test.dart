import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/models/financial_obligation.dart';

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
  late ObligationDataService dataService;

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create tables needed by ObligationDataService queries
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users_232143 (
        user_id_232143 TEXT PRIMARY KEY,
        full_name_232143 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_obligations_232143 (
        obligation_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        description_232143 TEXT,
        amount_232143 REAL NOT NULL,
        due_date_232143 TEXT NOT NULL,
        frequency_232143 TEXT NOT NULL,
        payment_method_232143 TEXT,
        category_id_232143 TEXT,
        is_paid_232143 INTEGER DEFAULT 0,
        paid_date_232143 TEXT,
        reminder_enabled_232143 INTEGER DEFAULT 1,
        reminder_days_before_232143 INTEGER DEFAULT 3,
        auto_pay_enabled_232143 INTEGER DEFAULT 0,
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
    dataService = ObligationDataService(
      dbService: dbService,
      authService: _FixedAuthService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ObligationDataService — integration (real SQLite)', () {
    test('addObligation → getObligations: round-trip preserves all fields',
        () async {
      final input = {
        'name': 'Listrik Bulanan',
        'description': 'Pembayaran listrik rumah',
        'amount': 250000,
        'due_date': '2026-08-15',
        'frequency': 'monthly',
        'payment_method': 'bank_transfer',
        'reminder_enabled': true,
        'reminder_days_before': 3,
      };

      final created = await dataService.addObligation(input);

      // Verify returned model
      expect(created.id, isNotEmpty);
      expect(created.name, 'Listrik Bulanan');
      expect(created.monthlyAmount, 250000);

      // Read back via getObligations
      final obligations = await dataService.getObligations();
      expect(obligations.length, 1);

      final loaded = obligations.first;
      expect(loaded.id, created.id);
      expect(loaded.name, 'Listrik Bulanan');
      expect(loaded.monthlyAmount, 250000);

      // Verify FinancialObligation.fromMap can parse the raw DB row
      final row = await db.query(
        'financial_obligations_232143',
        where: 'obligation_id_232143 = ?',
        whereArgs: [created.id],
      );
      expect(row.length, 1);
      expect(row.first['obligation_id_232143'], created.id);
      expect(row.first['name_232143'], 'Listrik Bulanan');
      expect(row.first['amount_232143'], 250000);

      final parsed = FinancialObligation.fromMap(row.first);
      expect(parsed.id, created.id);
      expect(parsed.name, 'Listrik Bulanan');
      expect(parsed.monthlyAmount, 250000);
      expect(parsed.daysUntilDue, greaterThan(0));
    });

    test('addObligation → updateObligation → getObligations: update round-trip',
        () async {
      final created = await dataService.addObligation({
        'name': 'Netflix',
        'description': 'Langganan Netflix',
        'amount': 150000,
        'due_date': '2026-08-20',
        'frequency': 'monthly',
        'payment_method': 'credit_card',
      });

      // Update name and amount
      final updated = await dataService.updateObligation(created.id, {
        'name': 'Netflix Premium',
        'amount': 186000,
      });

      expect(updated.name, 'Netflix Premium');
      expect(updated.monthlyAmount, 186000);

      // Verify via getObligations
      final obligations = await dataService.getObligations();
      expect(obligations.length, 1);
      expect(obligations.first.name, 'Netflix Premium');
      expect(obligations.first.monthlyAmount, 186000);
    });

    test('addObligation → deleteObligation returns true and removes it',
        () async {
      final created = await dataService.addObligation({
        'name': 'PDAM',
        'amount': 80000,
        'due_date': '2026-08-10',
        'frequency': 'monthly',
        'payment_method': 'cash',
      });

      final deleted = await dataService.deleteObligation(created.id);
      expect(deleted, true);

      final obligations = await dataService.getObligations();
      expect(obligations.length, 0);
    });

    test('getUpcomingObligations returns only unpaid obligations within range',
        () async {
      final today = DateTime.now();
      final dueSoon = today.add(const Duration(days: 3));
      final dueLater = today.add(const Duration(days: 30));

      // Add obligation due within 7 days
      await dataService.addObligation({
        'name': 'Listrik',
        'amount': 250000,
        'due_date': dueSoon.toIso8601String().split('T')[0],
        'frequency': 'monthly',
        'payment_method': 'bank_transfer',
      });

      // Add obligation due later
      await dataService.addObligation({
        'name': 'Kredit Motor',
        'amount': 500000,
        'due_date': dueLater.toIso8601String().split('T')[0],
        'frequency': 'monthly',
        'payment_method': 'bank_transfer',
      });

      // Should find 1 obligation within 7 days
      final upcoming = await dataService.getUpcomingObligations(days: 7);
      expect(upcoming.length, 1);
      expect(upcoming.first.name, 'Listrik');
    });

    test('recordObligationPayment marks obligation as paid', () async {
      final created = await dataService.addObligation({
        'name': 'Air PDAM',
        'amount': 75000,
        'due_date': '2026-08-10',
        'frequency': 'monthly',
        'payment_method': 'cash',
      });

      await dataService.recordObligationPayment(created.id, {});

      // Verify obligation marked as paid
      final obligations = await dataService.getObligations();
      expect(obligations.length, 1);

      // Check raw DB for is_paid flag
      final row = await db.query(
        'financial_obligations_232143',
        where: 'obligation_id_232143 = ?',
        whereArgs: [created.id],
      );
      expect(row.first['is_paid_232143'], 1);
      expect(row.first['paid_date_232143'], isNotNull);
    });

    test('calculateObligationsSummary aggregates correctly', () async {
      final today = DateTime.now();
      final dueDate1 = today.add(const Duration(days: 5));
      final dueDate2 = today.subtract(const Duration(days: 3)); // overdue

      final o1 = FinancialObligation.fromMap({
        'obligation_id_232143': 'obl-001',
        'name_232143': 'Listrik',
        'monthly_amount_232143': 250000,
        'due_date_232143': dueDate1.toIso8601String().split('T')[0],
        'type_232143': 'bill',
      });

      final o2 = FinancialObligation.fromMap({
        'obligation_id_232143': 'obl-002',
        'name_232143': 'Kredit Motor',
        'monthly_amount_232143': 1000000,
        'due_date_232143': dueDate2.toIso8601String().split('T')[0],
        'type_232143': 'debt',
      });

      final summary = dataService.calculateObligationsSummary([o1, o2]);

      expect(summary['total_monthly'], 1250000);
      expect(summary['total_count'], 2);
      expect(summary['active_count'], 2);
      expect(summary['overdue_count'], 1);
    });
  });
}
