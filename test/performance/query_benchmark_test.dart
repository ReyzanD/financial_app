// Benchmarks transaction query patterns at scale (50k rows).
// Phase 5 - Performance under scale.
// Measures query times before and after adding targeted indexes.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' show Database;
import 'seed_data.dart';

const _queryLabels = <String>[
  'Q1:  No filters, LIMIT 100',
  'Q2:  Type=income, LIMIT 100',
  'Q3:  Category=shopping, LIMIT 100',
  'Q4:  Date range 30d, LIMIT 100',
  'Q5:  LIKE description, LIMIT 100',
  'Q6:  Type+Category+Date, LIMIT 100',
  'Q7:  Monthly GROUP BY type',
  'Q8:  Category trend (SUM expense)',
  'Q9:  COUNT date range 6mo',
  'Q10: COUNT all (50k rows)',
];

const _warmupRuns = 2;
const _measureRuns = 5;

void main() {
  const userId = 'bench-user-001';
  const rowCount = 50000;

  final categoryIds = <String>[
    'cat-food',
    'cat-transport',
    'cat-shopping',
    'cat-entertainment',
    'cat-health',
    'cat-education',
    'cat-bills',
    'cat-savings',
  ];
  final accountIds = <String>[
    'acct-cash',
    'acct-bank-a',
    'acct-bank-b',
    'acct-ewallet',
  ];

  group('Transaction query benchmarks ($rowCount rows)', () {
    List<List<dynamic>> rows = [];

    setUpAll(() {
      databaseFactory = databaseFactoryFfi;

      rows = generateTransactionRows(
        count: rowCount,
        userId: userId,
        categoryIds: categoryIds,
        accountIds: accountIds,
      );
    });

    // Test 1: Baseline (existing indexes only)
    test('Baseline - current 2 indexes', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final results = await _benchmarkRun(
        db: db,
        rows: rows,
        extraIndexStatements: <String>[],
      );
      _printResults('BASELINE', results);
      await db.close();
    });

    // Test 2: Optimized (+3 targeted indexes)
    test('Optimized - +3 targeted indexes', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      final results = await _benchmarkRun(
        db: db,
        rows: rows,
        extraIndexStatements: <String>[
          // Mirrors the production index added in DB v9.
          'CREATE INDEX IF NOT EXISTS idx_transactions_category '
              'ON transactions_232143(category_id_232143)',
        ],
      );
      _printResults('OPTIMIZED', results);
      await db.close();
    });
  });
}

Future<Map<String, List<double>>> _benchmarkRun({
  required Database db,
  required List<List<dynamic>> rows,
  required List<String> extraIndexStatements,
}) async {
  await _createSchema(db, extraIndexStatements);
  await _seed(db, rows);

  final count =
      (await db.rawQuery(
            'SELECT COUNT(*) as c FROM transactions_232143 WHERE user_id_232143 = ?',
            ['bench-user-001'],
          )).first['c']
          as int;
  if (count != rows.length) {
    throw Exception('Seed failed: expected ${rows.length}, got $count');
  }

  // Warmup
  for (int w = 0; w < _warmupRuns; w++) {
    await _runQueries(db);
  }

  // Measure
  final allSamples = <String, List<double>>{};
  for (final label in _queryLabels) {
    allSamples[label] = <double>[];
  }

  for (int m = 0; m < _measureRuns; m++) {
    final samples = await _runQueries(db);
    for (int i = 0; i < samples.length; i++) {
      allSamples[_queryLabels[i]]!.add(samples[i]);
    }
  }

  await db.execute('DROP TABLE IF EXISTS transactions_232143');
  return allSamples;
}

Future<List<double>> _runQueries(Database db) async {
  const userId = 'bench-user-001';
  final samples = <double>[];

  // Q1
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT t.* FROM transactions_232143 t WHERE t.user_id_232143 = ? '
      'ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC '
      'LIMIT 100 OFFSET 0',
      [userId],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q2
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT t.* FROM transactions_232143 t WHERE t.user_id_232143 = ? '
      'AND t.type_232143 = ? '
      'ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC '
      'LIMIT 100 OFFSET 0',
      [userId, 'income'],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q3
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT t.* FROM transactions_232143 t WHERE t.user_id_232143 = ? '
      'AND t.category_id_232143 = ? '
      'ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC '
      'LIMIT 100 OFFSET 0',
      [userId, 'cat-shopping'],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q4
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT t.* FROM transactions_232143 t WHERE t.user_id_232143 = ? '
      'AND t.transaction_date_232143 >= ? '
      'AND t.transaction_date_232143 <= ? '
      'ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC '
      'LIMIT 100 OFFSET 0',
      [userId, '2026-06-16', '2026-07-16'],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q5
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT t.* FROM transactions_232143 t WHERE t.user_id_232143 = ? '
      'AND t.description_232143 LIKE ? '
      'ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC '
      'LIMIT 100 OFFSET 0',
      [userId, '%makan%'],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q6
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT t.* FROM transactions_232143 t WHERE t.user_id_232143 = ? '
      'AND t.type_232143 = ? AND t.category_id_232143 = ? '
      'AND t.transaction_date_232143 >= ? AND t.transaction_date_232143 <= ? '
      'ORDER BY t.transaction_date_232143 DESC, t.created_at_232143 DESC '
      'LIMIT 100 OFFSET 0',
      [userId, 'expense', 'cat-food', '2026-01-01', '2026-07-16'],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q7
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT type_232143, SUM(amount_232143) as total_amount, '
      'COUNT(*) as transaction_count '
      'FROM transactions_232143 WHERE user_id_232143 = ? '
      'AND transaction_date_232143 >= ? AND transaction_date_232143 <= ? '
      'GROUP BY type_232143',
      [userId, '2026-06-01', '2026-06-30'],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q8
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT COALESCE(SUM(amount_232143), 0) as total '
      'FROM transactions_232143 WHERE user_id_232143 = ? '
      'AND category_id_232143 = ? AND type_232143 = \'expense\' '
      'AND transaction_date_232143 >= ? AND transaction_date_232143 < ?',
      [userId, 'cat-transport', '2026-06-01', '2026-07-01'],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q9
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions_232143 '
      'WHERE user_id_232143 = ? '
      'AND transaction_date_232143 >= ? AND transaction_date_232143 <= ?',
      [userId, '2026-01-01', '2026-07-16'],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  // Q10
  {
    final sw = Stopwatch()..start();
    await db.rawQuery(
      'SELECT COUNT(*) as count FROM transactions_232143 '
      'WHERE user_id_232143 = ?',
      [userId],
    );
    sw.stop();
    samples.add(sw.elapsed.inMicroseconds / 1000.0);
  }

  return samples;
}

Future<void> _createSchema(Database db, List<String> extraIndexes) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS transactions_232143 (
      transaction_id_232143 TEXT PRIMARY KEY,
      user_id_232143 TEXT NOT NULL,
      account_id_232143 TEXT,
      amount_232143 REAL NOT NULL,
      type_232143 TEXT NOT NULL,
      category_id_232143 TEXT,
      description_232143 TEXT NOT NULL,
      location_name_232143 TEXT,
      latitude_232143 REAL,
      longitude_232143 REAL,
      location_data_232143 TEXT,
      payment_method_232143 TEXT,
      receipt_image_url_232143 TEXT,
      is_recurring_232143 INTEGER DEFAULT 0,
      recurring_pattern_232143 TEXT,
      predicted_category_id_232143 TEXT,
      confidence_score_232143 REAL,
      is_verified_232143 INTEGER DEFAULT 1,
      tags_232143 TEXT,
      transaction_date_232143 TEXT NOT NULL,
      transaction_time_232143 TEXT,
      created_at_232143 TEXT,
      updated_at_232143 TEXT
    )
  ''');

  // Existing indexes
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_transactions_user_date '
    'ON transactions_232143(user_id_232143, transaction_date_232143)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_transactions_type_date '
    'ON transactions_232143(type_232143, transaction_date_232143)',
  );

  for (final idx in extraIndexes) {
    await db.execute(idx);
  }
}

Future<void> _seed(Database db, List<List<dynamic>> rows) async {
  final batch = db.batch();
  for (final row in rows) {
    batch.rawInsert(
      'INSERT INTO transactions_232143 ('
      'transaction_id_232143, user_id_232143, account_id_232143, '
      'amount_232143, type_232143, category_id_232143, '
      'description_232143, location_name_232143, latitude_232143, '
      'longitude_232143, location_data_232143, payment_method_232143, '
      'receipt_image_url_232143, is_recurring_232143, recurring_pattern_232143, '
      'predicted_category_id_232143, confidence_score_232143, is_verified_232143, '
      'tags_232143, transaction_date_232143, transaction_time_232143, '
      'created_at_232143, updated_at_232143'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      row,
    );
  }
  await batch.commit(noResult: true);
}

void _printResults(String label, Map<String, List<double>> samples) {
  print('\n==========================================');
  print('  RESULTS - $label');
  print('==========================================');
  print('  $_measureRuns runs per query\n');

  for (final qLabel in _queryLabels) {
    final vals = samples[qLabel]!;
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final min = vals.reduce((a, b) => a < b ? a : b);
    final max = vals.reduce((a, b) => a > b ? a : b);
    print(
      '  ${qLabel.padRight(38)} '
      'avg: ${avg.toStringAsFixed(1).padLeft(8)}ms  '
      '(min: ${min.toStringAsFixed(1).padLeft(7)}ms  '
      'max: ${max.toStringAsFixed(1).padLeft(7)}ms)',
    );
  }
  print('');
}
