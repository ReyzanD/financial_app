import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/models/subscription_model.dart';
import 'package:financial_app/models/feature_models.dart';
import 'package:financial_app/models/transaction_model.dart';

void main() {
  final testDate = DateTime(2025, 1, 15, 10, 30);

  group('AccountModel', () {
    test('should create account with required fields', () {
      final account = AccountModel(
        id: 'acc_1',
        name: 'BCA',
        type: 'bank',
        balance: 1000000.0,
        createdAt: testDate,
      );

      expect(account.id, 'acc_1');
      expect(account.name, 'BCA');
      expect(account.type, 'bank');
      expect(account.balance, 1000000.0);
      expect(account.currency, 'IDR');
      expect(account.isActive, true);
      expect(account.isDefault, false);
    });

    test('toMap should return SQLite-compatible map', () {
      final account = AccountModel(
        id: 'acc_1',
        name: 'BCA',
        type: 'bank',
        balance: 1000000.0,
        createdAt: testDate,
      );

      final map = account.toMap();
      expect(map['account_id_232143'], 'acc_1');
      expect(map['name_232143'], 'BCA');
      expect(map['type_232143'], 'bank');
      expect(map['balance_232143'], 1000000.0);
    });

    test('fromMap should parse SQLite data correctly', () {
      final map = {
        'account_id_232143': 'acc_1',
        'name_232143': 'BCA',
        'type_232143': 'bank',
        'balance_232143': 1000000.0,
        'currency_232143': 'IDR',
        'is_active_232143': 1,
        'is_default_232143': 0,
        'created_at_232143': '2025-01-15T10:30:00',
      };

      final account = AccountModel.fromMap(map);
      expect(account.id, 'acc_1');
      expect(account.name, 'BCA');
      expect(account.balance, 1000000.0);
      expect(account.isActive, true);
    });

    test('fromJson should handle fallback field names', () {
      final json = {
        'id': 'acc_1',
        'name': 'BCA',
        'type': 'bank',
        'balance': 1000000.0,
        'created_at': '2025-01-15T10:30:00',
      };

      final account = AccountModel.fromJson(json);
      expect(account.id, 'acc_1');
      expect(account.name, 'BCA');
    });

    test('copyWith should update specified fields', () {
      final account = AccountModel(
        id: 'acc_1',
        name: 'BCA',
        type: 'bank',
        balance: 1000000.0,
        createdAt: testDate,
      );

      final updated = account.copyWith(balance: 2000000.0);
      expect(updated.balance, 2000000.0);
      expect(updated.name, 'BCA');
    });

    test('types should return supported types', () {
      expect(AccountModel.types, contains('cash'));
      expect(AccountModel.types, contains('bank'));
      expect(AccountModel.types, contains('e_wallet'));
    });

    test('defaultAccounts should have at least 3 accounts', () {
      expect(AccountModel.defaultAccounts.length, greaterThanOrEqualTo(3));
    });
  });

  group('DebtModel', () {
    test('should create debt with required fields', () {
      final debt = DebtModel(
        id: 'debt_1',
        name: 'Personal Loan',
        originalAmount: 10000000.0,
        currentBalance: 8000000.0,
        type: 'personal',
        startDate: testDate,
        createdAt: testDate,
      );

      expect(debt.id, 'debt_1');
      expect(debt.originalAmount, 10000000.0);
      expect(debt.currentBalance, 8000000.0);
      expect(debt.type, 'personal');
      expect(debt.interestRate, 0);
    });

    test('should calculate months remaining with zero interest', () {
      final debt = DebtModel(
        id: 'debt_1',
        name: 'Loan',
        originalAmount: 10000000.0,
        currentBalance: 1000000.0,
        type: 'personal',
        monthlyPayment: 500000.0,
        startDate: testDate,
        createdAt: testDate,
      );

      expect(debt.monthsRemaining, 0);
    });

    test('toMap should return SQLite-compatible map', () {
      final debt = DebtModel(
        id: 'debt_1',
        name: 'Personal Loan',
        originalAmount: 10000000.0,
        currentBalance: 8000000.0,
        type: 'personal',
        startDate: testDate,
        createdAt: testDate,
      );

      final map = debt.toMap();
      expect(map['name'], 'Personal Loan');
      expect(map['original_amount'], 10000000.0);
      expect(map['type'], 'personal');
    });

    test('fromMap should parse SQLite data correctly', () {
      final map = {
        'debt_id_232143': 'debt_1',
        'name_232143': 'Personal Loan',
        'original_amount_232143': 10000000.0,
        'current_balance_232143': 8000000.0,
        'interest_rate_232143': 12.0,
        'type_232143': 'personal',
        'start_date_232143': '2025-01-15',
        'created_at_232143': '2025-01-15T10:30:00',
      };

      final debt = DebtModel.fromMap(map);
      expect(debt.id, 'debt_1');
      expect(debt.name, 'Personal Loan');
      expect(debt.interestRate, 12.0);
    });

    test('types should include all debt types', () {
      expect(DebtModel.types.length, greaterThanOrEqualTo(7));
      expect(DebtModel.types, contains('mortgage'));
      expect(DebtModel.types, contains('student'));
    });
  });

  group('SubscriptionModel', () {
    test('should create subscription with required fields', () {
      final sub = SubscriptionModel(
        id: 'sub_1',
        name: 'Netflix',
        cost: 150000.0,
        cycle: 'monthly',
        startDate: testDate,
        nextRenewal: testDate,
        createdAt: testDate,
      );

      expect(sub.id, 'sub_1');
      expect(sub.name, 'Netflix');
      expect(sub.cost, 150000.0);
      expect(sub.cycle, 'monthly');
    });

    test('monthlyCost should convert weekly correctly', () {
      final sub = SubscriptionModel(
        id: 'sub_1',
        name: 'Weekly Service',
        cost: 10000.0,
        cycle: 'weekly',
        startDate: testDate,
        createdAt: testDate,
      );

      expect(sub.monthlyCost, closeTo(43300.0, 1.0));
    });

    test('monthlyCost should convert yearly correctly', () {
      final sub = SubscriptionModel(
        id: 'sub_1',
        name: 'Yearly Service',
        cost: 1200000.0,
        cycle: 'yearly',
        startDate: testDate,
        createdAt: testDate,
      );

      expect(sub.monthlyCost, 100000.0);
    });

    test('toMap should return SQLite-compatible map', () {
      final sub = SubscriptionModel(
        id: 'sub_1',
        name: 'Netflix',
        cost: 150000.0,
        cycle: 'monthly',
        startDate: testDate,
        nextRenewal: testDate,
        createdAt: testDate,
      );

      final map = sub.toMap();
      expect(map['name'], 'Netflix');
      expect(map['cost'], 150000.0);
      expect(map['cycle'], 'monthly');
    });

    test('fromJson should parse subscription data', () {
      final json = {
        'id': 'sub_1',
        'name': 'Spotify',
        'cost': 50000.0,
        'cycle': 'monthly',
        'next_renewal_date': '2025-02-15',
        'created_at': '2025-01-15T10:30:00',
      };

      final sub = SubscriptionModel.fromJson(json);
      expect(sub.name, 'Spotify');
      expect(sub.cost, 50000.0);
    });
  });

  group('TransactionTagModel', () {
    test('should create tag with required fields', () {
      final tag = TransactionTagModel(
        id: 'tag_1',
        name: 'Vacation',
        color: '#FF5722',
        createdAt: testDate,
      );

      expect(tag.id, 'tag_1');
      expect(tag.name, 'Vacation');
      expect(tag.color, '#FF5722');
      expect(tag.usageCount, 0);
    });

    test('toJson should return serializable data', () {
      final tag = TransactionTagModel(
        id: 'tag_1',
        name: 'Vacation',
        color: '#FF5722',
        createdAt: testDate,
      );

      final json = tag.toJson();
      expect(json['id'], 'tag_1');
      expect(json['name'], 'Vacation');
    });

    test('fromMap should parse SQLite data', () {
      final map = {
        'tag_id_232143': 'tag_1',
        'name_232143': 'Food',
        'color_232143': '#4CAF50',
        'created_at_232143': '2025-01-15T10:30:00',
      };

      final tag = TransactionTagModel.fromMap(map);
      expect(tag.id, 'tag_1');
      expect(tag.name, 'Food');
    });
  });

  group('SplitModel', () {
    test('should create split with required fields', () {
      final split = SplitModel(
        id: 'split_1',
        transactionId: 'txn_1',
        participantName: 'John',
        amount: 50000.0,
        createdAt: testDate,
      );

      expect(split.id, 'split_1');
      expect(split.participantName, 'John');
      expect(split.amount, 50000.0);
      expect(split.remainingAmount, 50000.0);
      expect(split.isSettled, false);
    });

    test(
      'remainingAmount should calculate correctly after partial payment',
      () {
        final split = SplitModel(
          id: 'split_1',
          transactionId: 'txn_1',
          participantName: 'John',
          amount: 100000.0,
          paidAmount: 30000.0,
          createdAt: testDate,
        );

        expect(split.remainingAmount, 70000.0);
      },
    );

    test('toMap should return SQLite-compatible data', () {
      final split = SplitModel(
        id: 'split_1',
        transactionId: 'txn_1',
        participantName: 'John',
        amount: 50000.0,
        createdAt: testDate,
      );

      final map = split.toMap();
      expect(map['transaction_id'], 'txn_1');
      expect(map['participant_name'], 'John');
      expect(map['amount'], 50000.0);
    });

    test('fromMap should parse SQLite data', () {
      final map = {
        'split_id_232143': 'split_1',
        'transaction_id_232143': 'txn_1',
        'participant_name_232143': 'Jane',
        'amount_232143': 75000.0,
        'is_settled_232143': 0,
        'created_at_232143': '2025-01-15T10:30:00',
      };

      final split = SplitModel.fromMap(map);
      expect(split.id, 'split_1');
      expect(split.participantName, 'Jane');
      expect(split.remainingAmount, 75000.0);
    });
  });

  group('ChallengeModel', () {
    test('should create challenge with required fields', () {
      final challenge = ChallengeModel(
        id: 'challenge_1',
        name: 'No Spend January',
        type: 'no_spend',
        target: 1000000.0,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        createdAt: testDate,
      );

      expect(challenge.id, 'challenge_1');
      expect(challenge.name, 'No Spend January');
      expect(challenge.isActive, true);
    });

    test('progressPercentage should calculate correctly', () {
      final challenge = ChallengeModel(
        id: 'challenge_1',
        name: 'Save Challenge',
        type: 'savings',
        target: 1000000.0,
        currentProgress: 500000.0,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        createdAt: testDate,
      );

      expect(challenge.progressPercentage, 50.0);
    });

    test('toMap should return serializable data', () {
      final challenge = ChallengeModel(
        id: 'challenge_1',
        name: 'Save Challenge',
        type: 'savings',
        target: 1000000.0,
        currentProgress: 500000.0,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        createdAt: testDate,
      );

      final map = challenge.toMap();
      expect(map['name'], 'Save Challenge');
      expect(map['target_amount'], 1000000.0);
    });

    test('fromMap should parse SQLite data', () {
      final map = {
        'challenge_id_232143': 'challenge_1',
        'name_232143': 'No Spend',
        'type_232143': 'no_spend',
        'target_amount_232143': 500000.0,
        'current_amount_232143': 250000.0,
        'start_date_232143': '2025-01-01',
        'end_date_232143': '2025-01-31',
        'is_active_232143': 1,
        'created_at_232143': '2025-01-15T10:30:00',
      };

      final challenge = ChallengeModel.fromMap(map);
      expect(challenge.id, 'challenge_1');
      expect(challenge.progressPercentage, 50.0);
    });
  });

  group('TransactionModel with Account Linking', () {
    test('should parse account fields from database result', () {
      final json = {
        'transaction_id_232143': 'txn_1',
        'amount_232143': 100000.0,
        'type_232143': 'expense',
        'description_232143': 'Lunch',
        'category_name': 'Food',
        'category_color': '#FF5722',
        'payment_method_232143': 'cash',
        'transaction_date_232143': '2025-01-15',
        'created_at_232143': '2025-01-15T10:30:00',
        'account_id_232143': 'acc_1',
        'account_name': 'BCA',
        'account_type': 'bank',
      };

      final tx = TransactionModel.fromJson(json);
      expect(tx.id, 'txn_1');
      expect(tx.accountId, 'acc_1');
      expect(tx.accountName, 'BCA');
      expect(tx.accountType, 'bank');
    });

    test('should handle null account fields gracefully', () {
      final json = {
        'transaction_id_232143': 'txn_1',
        'amount_232143': 50000.0,
        'type_232143': 'income',
        'description_232143': 'Salary',
        'category_name': 'Salary',
        'category_color': '#4CAF50',
        'payment_method_232143': 'bank_transfer',
        'transaction_date_232143': '2025-01-15',
        'created_at_232143': '2025-01-15T10:30:00',
      };

      final tx = TransactionModel.fromJson(json);
      expect(tx.accountId, isNull);
      expect(tx.accountName, isNull);
    });
  });
}
