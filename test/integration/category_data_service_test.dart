import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:financial_app/services/data/category_data_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/models/category_model.dart';

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
  late CategoryDataService dataService;

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);

    // Create tables needed by CategoryDataService queries
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users_232143 (
        user_id_232143 TEXT PRIMARY KEY,
        full_name_232143 TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories_232143 (
        category_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT,
        name_232143 TEXT NOT NULL,
        type_232143 TEXT NOT NULL,
        color_232143 TEXT,
        icon_232143 TEXT,
        budget_limit_232143 REAL,
        budget_period_232143 TEXT,
        display_order_232143 INTEGER DEFAULT 0,
        is_system_default_232143 INTEGER DEFAULT 0,
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
    dataService = CategoryDataService(
      dbService: dbService,
      authService: _FixedAuthService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryDataService — integration (real SQLite)', () {
    test('addCategory → getCategories: round-trip preserves all fields',
        () async {
      final input = {
        'name': 'Transportasi',
        'type': 'expense',
        'color': '#3498DB',
        'icon': 'car',
        'budget_limit': 500000,
        'budget_period': 'monthly',
        'display_order': 2,
      };

      final created = await dataService.addCategory(input);

      // Verify returned model
      expect(created.id, isNotEmpty);
      expect(created.name, 'Transportasi');
      expect(created.type, 'expense');
      expect(created.color, '#3498DB');
      expect(created.icon, 'car');
      expect(created.budgetLimit, 500000);
      expect(created.budgetPeriod, 'monthly');
      expect(created.displayOrder, 2);

      // Read back via getCategories
      final categories = await dataService.getCategories();
      expect(categories.length, 1);

      final loaded = categories.first;
      expect(loaded.id, created.id);
      expect(loaded.name, 'Transportasi');
      expect(loaded.type, 'expense');

      // Verify CategoryModel.fromMap can parse the raw DB row
      final row = await db.query(
        'categories_232143',
        where: 'category_id_232143 = ?',
        whereArgs: [created.id],
      );
      expect(row.length, 1);
      expect(row.first['category_id_232143'], created.id);
      expect(row.first['name_232143'], 'Transportasi');

      final parsed = CategoryModel.fromMap(row.first);
      expect(parsed.id, created.id);
      expect(parsed.name, 'Transportasi');
      expect(parsed.budgetLimit, 500000);
    });

    test('addCategory → updateCategory → getCategories: update round-trip',
        () async {
      final created = await dataService.addCategory({
        'name': 'Makanan',
        'type': 'expense',
        'color': '#FF6B6B',
        'icon': 'food',
        'display_order': 1,
      });

      // Update name and color
      final updated = await dataService.updateCategory(created.id, {
        'name': 'Makanan & Minuman',
        'color': '#E74C3C',
      });

      expect(updated.name, 'Makanan & Minuman');
      expect(updated.color, '#E74C3C');

      // Verify via getCategories
      final categories = await dataService.getCategories();
      expect(categories.length, 1);
      expect(categories.first.name, 'Makanan & Minuman');
      expect(categories.first.color, '#E74C3C');
    });

    test('addCategory → deleteCategory removes it', () async {
      final created = await dataService.addCategory({
        'name': 'Belanja',
        'type': 'expense',
        'color': '#9B59B6',
        'icon': 'shopping',
        'display_order': 3,
      });

      await dataService.deleteCategory(created.id);

      final categories = await dataService.getCategories();
      expect(categories.length, 0);
    });

    test('getCategories returns only current user categories', () async {
      // Add category as test user
      await dataService.addCategory({
        'name': 'User Category',
        'type': 'expense',
        'color': '#2ECC71',
        'icon': 'wallet',
        'display_order': 1,
      });

      // Manually insert category for a different user
      await db.insert('categories_232143', {
        'category_id_232143': 'other-cat-001',
        'user_id_232143': 'other-user-999',
        'name_232143': 'Other User Category',
        'type_232143': 'expense',
        'color_232143': '#E74C3C',
        'icon_232143': 'receipt',
        'budget_period_232143': 'monthly',
        'display_order_232143': 1,
        'is_system_default_232143': 0,
        'created_at_232143': DateTime.now().toIso8601String(),
      });

      // Should only return test user's category
      final categories = await dataService.getCategories();
      expect(categories.length, 1);
      expect(categories.first.name, 'User Category');
    });
  });
}
