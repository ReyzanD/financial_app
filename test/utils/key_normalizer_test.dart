import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/utils/key_normalizer.dart';

void main() {
  group('KeyNormalizer.normalize', () {
    test('should strip _232143 suffix from all keys', () {
      final input = {
        'name_232143': 'Gaji',
        'amount_232143': 5000000,
        'type_232143': 'income',
      };
      final result = KeyNormalizer.normalize(input);
      expect(result['name'], 'Gaji');
      expect(result['amount'], 5000000);
      expect(result['type'], 'income');
    });

    test('should keep unsuffixed keys unchanged', () {
      final input = {'name': 'Gaji', 'amount': 5000000};
      final result = KeyNormalizer.normalize(input);
      expect(result['name'], 'Gaji');
      expect(result['amount'], 5000000);
    });

    test('should prefer existing clean keys over suffixed ones', () {
      final input = {'name': 'Existing Name', 'name_232143': 'Suffixed Name'};
      final result = KeyNormalizer.normalize(input);
      // Clean key already exists, so it should not be overwritten
      expect(result['name'], 'Existing Name');
    });

    test('should handle empty map', () {
      final result = KeyNormalizer.normalize({});
      expect(result, isEmpty);
    });

    test('should handle mixed suffixed and non-suffixed keys', () {
      final input = {
        'category_id_232143': 'cat_1',
        'name_232143': 'Makanan',
        'type_232143': 'expense',
        'color': '#FF0000', // unsuffixed
        'icon': 'food', // unsuffixed
      };
      final result = KeyNormalizer.normalize(input);
      expect(result['category_id'], 'cat_1');
      expect(result['name'], 'Makanan');
      expect(result['type'], 'expense');
      expect(result['color'], '#FF0000');
      expect(result['icon'], 'food');
      // Original suffixed keys should still be present
      expect(result['category_id_232143'], 'cat_1');
      expect(result['name_232143'], 'Makanan');
    });

    test('should handle keys that partially match the suffix', () {
      final input = {
        'test_232143': 'value1',
        'test_232144': 'value2', // different suffix, not stripped
      };
      final result = KeyNormalizer.normalize(input);
      expect(result['test'], 'value1');
      expect(result['test_232144'], 'value2');
    });
  });

  group('KeyNormalizer.normalizeList', () {
    test('should normalize a list of maps', () {
      final input = [
        {'name_232143': 'Item 1', 'amount_232143': 100},
        {'name_232143': 'Item 2', 'amount_232143': 200},
      ];
      final result = KeyNormalizer.normalizeList(input);
      expect(result.length, 2);
      expect(result[0]['name'], 'Item 1');
      expect(result[0]['amount'], 100);
      expect(result[1]['name'], 'Item 2');
      expect(result[1]['amount'], 200);
    });

    test('should handle empty list', () {
      final result = KeyNormalizer.normalizeList([]);
      expect(result, isEmpty);
    });

    test('should handle raw Map type (not typed)', () {
      final input = [
        {'id_232143': '1'} as Map,
        {'id_232143': '2'} as Map,
      ];
      final result = KeyNormalizer.normalizeList(input);
      expect(result.length, 2);
      expect(result[0]['id'], '1');
      expect(result[1]['id'], '2');
    });
  });

  group('KeyNormalizer.normalizeTransactions', () {
    test('should normalize transaction maps with all fields', () {
      final input = [
        {
          'transaction_date_232143': '2024-01-15',
          'type_232143': 'expense',
          'amount_232143': 50000,
          'category_name_232143': 'Makanan',
          'description_232143': 'Makan siang',
          'category_id_232143': 'cat_1',
          'category_color_232143': '#FF0000',
          'payment_method_232143': 'cash',
        },
      ];
      final result = KeyNormalizer.normalizeTransactions(input);
      expect(result.length, 1);
      final t = result[0];
      expect(t['transaction_date'], '2024-01-15');
      expect(t['date'], '2024-01-15');
      expect(t['type'], 'expense');
      expect(t['amount'], 50000.0);
      expect(t['category_name'], 'Makanan');
      expect(t['category_id'], 'cat_1');
      expect(t['category_color'], '#FF0000');
      expect(t['description'], 'Makan siang');
      expect(t['payment_method'], 'cash');
    });

    test('should provide sensible defaults for missing fields', () {
      final input = [
        {'type_232143': 'income', 'amount_232143': 100000},
      ];
      final result = KeyNormalizer.normalizeTransactions(input);
      expect(result.length, 1);
      final t = result[0];
      expect(t['transaction_date'], null);
      expect(t['type'], 'income');
      expect(t['amount'], 100000.0);
      expect(t['category_name'], 'Lainnya'); // default
      expect(t['description'], ''); // default
      expect(t['category_color'], '#8B5FBF'); // default
    });

    test('should fall back to unsuffixed keys', () {
      final input = [
        {
          'date': '2024-06-01',
          'type': 'expense',
          'amount': 25000.0,
          'category_name': 'Transportasi',
          'description': 'Bensin',
          'category_id': 'cat_2',
        },
      ];
      final result = KeyNormalizer.normalizeTransactions(input);
      expect(result.length, 1);
      final t = result[0];
      expect(t['transaction_date'], '2024-06-01');
      expect(t['date'], '2024-06-01');
      expect(t['type'], 'expense');
      expect(t['amount'], 25000.0);
      expect(t['category_name'], 'Transportasi');
      expect(t['category_id'], 'cat_2');
      expect(t['description'], 'Bensin');
    });

    test('should handle empty transaction list', () {
      final result = KeyNormalizer.normalizeTransactions([]);
      expect(result, isEmpty);
    });
  });
}
