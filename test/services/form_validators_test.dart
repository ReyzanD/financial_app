import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/utils/form_validators.dart';

void main() {
  group('FormValidators', () {
    group('validateAmount', () {
      test('should return null for valid amount', () {
        expect(FormValidators.validateAmount('100000'), isNull);
        expect(FormValidators.validateAmount('1000.50'), isNull);
      });

      test('should return error for empty amount', () {
        expect(FormValidators.validateAmount(''), isNotNull);
        expect(FormValidators.validateAmount(null), isNotNull);
      });

      test('should return error for invalid amount', () {
        expect(FormValidators.validateAmount('abc'), isNotNull);
        expect(FormValidators.validateAmount('12.34.56'), isNotNull);
      });

      test('should return error for amount exceeding max', () {
        expect(
          FormValidators.validateAmount('1000000000000'),
          isNotNull,
        );
      });

      test('should return error for amount below min', () {
        expect(FormValidators.validateAmount('0'), isNotNull);
        expect(FormValidators.validateAmount('-100'), isNotNull);
      });
    });

    group('validateDescription', () {
      test('should return null for valid description', () {
        expect(FormValidators.validateDescription('Valid description'), isNull);
        expect(FormValidators.validateDescription(null), isNull);
        expect(FormValidators.validateDescription(''), isNull);
      });

      test('should return error for description exceeding max length', () {
        final longDescription = 'a' * 501;
        expect(
          FormValidators.validateDescription(longDescription),
          isNotNull,
        );
      });

      test('should return error for malicious content', () {
        expect(
          FormValidators.validateDescription('<script>alert("xss")</script>'),
          isNotNull,
        );
      });
    });

    group('validateDate', () {
      test('should return null for valid past date', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        expect(FormValidators.validateDate(pastDate), isNull);
      });

      test('should return error for future date when not allowed', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        expect(FormValidators.validateDate(futureDate), isNotNull);
      });

      test('should return null for future date when allowed', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        expect(
          FormValidators.validateDate(futureDate, allowFuture: true),
          isNull,
        );
      });

      test('should return error for null date', () {
        expect(FormValidators.validateDate(null), isNotNull);
      });
    });

    group('isDuplicateTransaction', () {
      test('should detect duplicate transaction', () {
        final recentTransactions = [
          {
            'amount': 100000.0,
            'description': 'Test transaction',
            'date': DateTime.now().toIso8601String(),
          },
        ];

        final isDuplicate = FormValidators.isDuplicateTransaction(
          amount: 100000.0,
          description: 'Test transaction',
          date: DateTime.now(),
          recentTransactions: recentTransactions,
        );

        expect(isDuplicate, isTrue);
      });

      test('should not detect duplicate for different amount', () {
        final recentTransactions = [
          {
            'amount': 100000.0,
            'description': 'Test transaction',
            'date': DateTime.now().toIso8601String(),
          },
        ];

        final isDuplicate = FormValidators.isDuplicateTransaction(
          amount: 200000.0,
          description: 'Test transaction',
          date: DateTime.now(),
          recentTransactions: recentTransactions,
        );

        expect(isDuplicate, isFalse);
      });
    });
  });
}

