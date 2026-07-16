library seed_data;

import 'dart:math';

final _random = Random(42); // deterministic seed

/// Generates [count] synthetic transaction rows as list-of-values for
/// bulk INSERT. Each row matches the `transactions_232143` schema.
///
/// All rows share the same [userId] and draw from [categoryIds].
List<List<dynamic>> generateTransactionRows({
  required int count,
  required String userId,
  required List<String> categoryIds,
  required List<String> accountIds,
}) {
  const descriptions = [
    'Beli makanan siang',
    'Makan malam di restoran',
    'Bensin kendaraan',
    'Pulsa dan kuota internet',
    'Belanja bulanan',
    'Bayar listrik',
    'Bayar air',
    'Bayar internet',
    'Nonton bioskop',
    'Streaming bulanan',
    'Ojek online',
    'Belanja online',
    'Parkir kendaraan',
    'Kopi di kafe',
    'Fotokopi dan print',
    'Buku kuliah',
    'Vitamin dan obat',
    'Potong rambut',
    'Laundry',
    'Top up e-wallet',
    'Gaji bulanan',
    'Uang saku',
    'Bonus project',
    'Freelance design',
    'Hasil investasi',
  ];

  final types = ['expense', 'expense', 'expense', 'income']; // ~75% expense
  final paymentMethods = [
    'cash',
    'cash',
    'debit_card',
    'e_wallet',
    'e_wallet',
    'bank_transfer',
  ];

  final rows = <List<dynamic>>[];
  final now = DateTime(2026, 7, 16);
  final start = now.subtract(const Duration(days: 730)); // 2 years back

  for (int i = 0; i < count; i++) {
    final id = 'bench-txn-${i.toString().padLeft(7, '0')}';
    final type = types[_random.nextInt(types.length)];
    final amount =
        type == 'income'
            ? 50000.0 + _random.nextDouble() * 5000000.0
            : 2000.0 + _random.nextDouble() * 500000.0;
    final categoryId = categoryIds[_random.nextInt(categoryIds.length)];
    final description = descriptions[_random.nextInt(descriptions.length)];
    final accountId = accountIds[_random.nextInt(accountIds.length)];

    // Random date spread across 2 years
    final dayOffset = _random.nextInt(730);
    final date = start.add(Duration(days: dayOffset));
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${_random.nextInt(24).toString().padLeft(2, '0')}:${_random.nextInt(60).toString().padLeft(2, '0')}';

    rows.add([
      id,
      userId,
      accountId,
      amount,
      type,
      categoryId,
      description,
      null, // location_name
      null, // latitude
      null, // longitude
      null, // location_data
      paymentMethods[_random.nextInt(paymentMethods.length)],
      null, // receipt_image_url
      0, // is_recurring
      null, // recurring_pattern
      null, // predicted_category_id
      null, // confidence_score
      1, // is_verified
      null, // tags
      dateStr,
      timeStr,
      dateStr.substring(0, 7), // created_at (approx)
      dateStr, // updated_at
    ]);
  }

  return rows;
}
