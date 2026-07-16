import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:sqflite/sqflite.dart' show Database;

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
  late TransactionDataService dataService;

  setUpAll(() {
    // Use sqflite_common_ffi for desktop/test environment
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create in-memory database
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create the core tables needed by TransactionDataService queries
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
        type_232143 TEXT NOT NULL CHECK(type_232143 IN ('income','expense','transfer')),
        category_id_232143 TEXT,
        description_232143 TEXT,
        location_name_232143 TEXT,
        latitude_232143 REAL,
        longitude_232143 REAL,
        location_data_232143 TEXT,
        payment_method_232143 TEXT,
        receipt_image_url_232143 TEXT,
        is_recurring_232143 INTEGER DEFAULT 0,
        recurring_pattern_232143 TEXT,
        tags_232143 TEXT,
        transaction_date_232143 TEXT,
        transaction_time_232143 TEXT,
        notes_232143 TEXT,
        created_at_232143 TEXT,
        updated_at_232143 TEXT,
        is_deleted_232143 INTEGER DEFAULT 0,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143),
        FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
        FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143)
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

    // Insert test account
    await db.insert('accounts_232143', {
      'account_id_232143': 'acc-cash-001',
      'user_id_232143': 'test-user-001',
      'name_232143': 'Cash',
      'type_232143': 'cash',
      'balance_232143': 1000000,
      'color_232143': '#4CAF50',
    });

    dbService = _TestDatabaseService(db);
    dataService = TransactionDataService(
      dbService: dbService,
      authService: _FixedAuthService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionDataService — integration (real SQLite)', () {
    test(
      'addTransaction → getTransactions: round-trip preserves all fields',
      () async {
        final input = {
          'amount': 50000,
          'type': 'expense',
          'category_id': 'cat-food-001',
          'category_name': 'Makanan & Minuman',
          'category_color': '#FF6B6B',
          'category_icon': 'food',
          'description': 'Nasi Goreng',
          'account_id': 'acc-cash-001',
          'account_name': 'Cash',
          'account_type': 'cash',
          'payment_method': 'cash',
          'transaction_date': '2026-07-15',
          'is_recurring': false,
        };

        final created = await dataService.addTransaction(input);

        // Verify the returned model has correct fields
        expect(created.id, isNotEmpty);
        expect(created.amount, 50000);
        expect(created.type, 'expense');
        expect(created.categoryId, 'cat-food-001');
        expect(created.categoryName, 'Makanan & Minuman');
        expect(created.description, 'Nasi Goreng');
        expect(created.accountId, 'acc-cash-001');

        // Read back via getTransactions
        final result = await dataService.getTransactions(limit: 10, offset: 0);
        final transactions =
            result['transactions'] as List<Map<String, dynamic>>;

        expect(transactions.length, 1);
        final row = transactions.first;

        // Verify the raw DB row has suffixed keys (_232143)
        expect(row['transaction_id_232143'], created.id);
        expect(row['amount_232143'], 50000);
        expect(row['description_232143'], 'Nasi Goreng');
        expect(row['category_name'], 'Makanan & Minuman'); // JOIN alias

        // Verify TransactionModel.fromMap can parse the raw row
        final parsed = TransactionModel.fromMap(row);
        expect(parsed.id, created.id);
        expect(parsed.amount, 50000);
        expect(parsed.categoryName, 'Makanan & Minuman');
      },
    );

    test(
      'addTransaction → getTransaction: single lookup returns correct model',
      () async {
        final input = {
          'amount': 150000,
          'type': 'income',
          'category_id': 'cat-food-001',
          'category_name': 'Makanan & Minuman',
          'category_color': '#FF6B6B',
          'description': 'Gaji',
          'transaction_date': '2026-07-01',
        };

        final created = await dataService.addTransaction(input);
        final fetched = await dataService.getTransaction(created.id);

        expect(fetched, isNotNull);
        expect(fetched!.id, created.id);
        expect(fetched.amount, 150000);
        expect(fetched.type, 'income');
        expect(fetched.description, 'Gaji');
      },
    );

    test(
      'addTransaction → updateTransaction → getTransaction: update round-trip',
      () async {
        final input = {
          'amount': 75000,
          'type': 'expense',
          'category_id': 'cat-food-001',
          'category_name': 'Makanan & Minuman',
          'category_color': '#FF6B6B',
          'description': 'Makan Siang',
        };

        final created = await dataService.addTransaction(input);

        // Update description and amount
        await dataService.updateTransaction(created.id, {
          'amount': 80000,
          'type': 'expense',
          'category_id': 'cat-food-001',
          'category_name': 'Makanan & Minuman',
          'category_color': '#FF6B6B',
          'description': 'Makan Malam',
          'transaction_date': '2026-07-15',
        });

        final fetched = await dataService.getTransaction(created.id);
        expect(fetched, isNotNull);
        expect(fetched!.description, 'Makan Malam');
        expect(fetched.amount, 80000);
      },
    );

    test(
      'addTransaction → deleteTransaction → getTransaction returns null',
      () async {
        final input = {
          'amount': 25000,
          'type': 'expense',
          'category_id': 'cat-food-001',
          'category_name': 'Makanan & Minuman',
          'category_color': '#FF6B6B',
          'description': 'Snack',
        };

        final created = await dataService.addTransaction(input);
        await dataService.deleteTransaction(created.id);

        final fetched = await dataService.getTransaction(created.id);
        expect(fetched, isNull);
      },
    );

    test('getTransactions respects pagination (limit/offset)', () async {
      // Insert 5 transactions
      for (int i = 1; i <= 5; i++) {
        await dataService.addTransaction({
          'amount': i * 10000,
          'type': 'expense',
          'category_id': 'cat-food-001',
          'category_name': 'Makanan & Minuman',
          'category_color': '#FF6B6B',
          'description': 'Transaksi ke-$i',
          'transaction_date': '2026-07-${i.toString().padLeft(2, '0')}',
        });
      }

      // Page 1: limit 2
      final page1 = await dataService.getTransactions(limit: 2, offset: 0);
      expect(page1['count'], 2);
      expect(page1['total'], 5);
      expect(page1['hasMore'], true);

      // Page 2: limit 2, offset 2
      final page2 = await dataService.getTransactions(limit: 2, offset: 2);
      expect(page2['count'], 2);
      expect(page2['hasMore'], true);

      // Page 3: limit 2, offset 4
      final page3 = await dataService.getTransactions(limit: 2, offset: 4);
      expect(page3['count'], 1);
      expect(page3['hasMore'], false);
    });

    test('getTransactions filters by type (income / expense)', () async {
      await dataService.addTransaction({
        'amount': 50000,
        'type': 'expense',
        'category_id': 'cat-food-001',
        'category_name': 'Makanan & Minuman',
        'category_color': '#FF6B6B',
        'description': 'Belanja',
        'transaction_date': '2026-07-10',
      });

      await dataService.addTransaction({
        'amount': 1000000,
        'type': 'income',
        'category_id': 'cat-food-001',
        'category_name': 'Makanan & Minuman',
        'category_color': '#FF6B6B',
        'description': 'Gaji',
        'transaction_date': '2026-07-01',
      });

      final expenses = await dataService.getTransactions(
        limit: 10,
        offset: 0,
        type: 'expense',
      );
      expect(expenses['count'], 1);
      expect(
        (expenses['transactions'] as List).first['description_232143'],
        'Belanja',
      );

      final incomes = await dataService.getTransactions(
        limit: 10,
        offset: 0,
        type: 'income',
      );
      expect(incomes['count'], 1);
      expect(
        (incomes['transactions'] as List).first['description_232143'],
        'Gaji',
      );
    });

    test('getTransactions searches by description', () async {
      await dataService.addTransaction({
        'amount': 50000,
        'type': 'expense',
        'category_id': 'cat-food-001',
        'category_name': 'Makanan & Minuman',
        'category_color': '#FF6B6B',
        'description': 'Nasi Goreng spesial',
        'transaction_date': '2026-07-10',
      });

      await dataService.addTransaction({
        'amount': 30000,
        'type': 'expense',
        'category_id': 'cat-food-001',
        'category_name': 'Makanan & Minuman',
        'category_color': '#FF6B6B',
        'description': 'Es Teh Manis',
        'transaction_date': '2026-07-10',
      });

      final result = await dataService.getTransactions(
        limit: 10,
        offset: 0,
        search: 'Nasi',
      );
      expect(result['count'], 1);
      expect(
        (result['transactions'] as List).first['description_232143'],
        'Nasi Goreng spesial',
      );
    });

    test('getTransactions filters by date range', () async {
      await dataService.addTransaction({
        'amount': 50000,
        'type': 'expense',
        'category_id': 'cat-food-001',
        'category_name': 'Makanan & Minuman',
        'category_color': '#FF6B6B',
        'description': 'Juli',
        'transaction_date': '2026-07-15',
      });

      await dataService.addTransaction({
        'amount': 50000,
        'type': 'expense',
        'category_id': 'cat-food-001',
        'category_name': 'Makanan & Minuman',
        'category_color': '#FF6B6B',
        'description': 'Agustus',
        'transaction_date': '2026-08-01',
      });

      final result = await dataService.getTransactions(
        limit: 10,
        offset: 0,
        startDate: '2026-07-01',
        endDate: '2026-07-31',
      );
      expect(result['count'], 1);
      expect(
        (result['transactions'] as List).first['description_232143'],
        'Juli',
      );
    });
  });
}
