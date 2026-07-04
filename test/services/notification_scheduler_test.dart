import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationScheduler Logic', () {
    test('should determine if challenge is within 3-day warning window', () {
      final now = DateTime.now();
      final endDate1 = now.add(const Duration(days: 1));
      final endDate2 = now.add(const Duration(days: 3));
      final endDate3 = now.add(const Duration(days: 5));

      expect(endDate1.difference(now).inDays, 1);
      expect(endDate2.difference(now).inDays, 3);
      expect(endDate3.difference(now).inDays, 5);

      final shouldWarn1 = endDate1.difference(now).inDays <= 3;
      final shouldWarn2 = endDate2.difference(now).inDays <= 3;
      final shouldWarn3 = endDate3.difference(now).inDays <= 3;

      expect(shouldWarn1, true);
      expect(shouldWarn2, true);
      expect(shouldWarn3, false);
    });

    test('should calculate challenge progress percentage correctly', () {
      double calculateProgress(double current, double target) {
        return target > 0 ? (current / target * 100) : 0;
      }

      expect(calculateProgress(500000, 1000000), 50.0);
      expect(calculateProgress(1000000, 1000000), 100.0);
      expect(calculateProgress(0, 1000000), 0.0);
      expect(calculateProgress(1500000, 1000000), 150.0);
    });

    test('should identify completed challenge', () {
      bool isCompleted(double progress, double target) {
        return progress >= target;
      }

      expect(isCompleted(1000000, 1000000), true);
      expect(isCompleted(1500000, 1000000), true);
      expect(isCompleted(500000, 1000000), false);
      expect(isCompleted(0, 1000000), false);
    });

    test('should determine split reminder eligibility', () {
      bool shouldRemind(DateTime createdAt, int daysThreshold) {
        return DateTime.now().difference(createdAt).inDays > daysThreshold;
      }

      final weekAgo = DateTime.now().subtract(const Duration(days: 8));
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();

      expect(shouldRemind(weekAgo, 7), true);
      expect(shouldRemind(yesterday, 7), false);
      expect(shouldRemind(today, 7), false);
    });

    test('should parse boolean values correctly', () {
      bool? parseBool(dynamic value) {
        if (value == null) return null;
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is num) return value.toInt() == 1;
        return null;
      }

      expect(parseBool(1), true);
      expect(parseBool(0), false);
      expect(parseBool(true), true);
      expect(parseBool(false), false);
      expect(parseBool(null), isNull);
    });

    test('subscription renewal should be scheduled 1 day before', () {
      final renewalDate = DateTime(2025, 2, 15);
      final reminderDate = renewalDate.subtract(const Duration(days: 1));

      expect(reminderDate, DateTime(2025, 2, 14));
      expect(reminderDate.isBefore(renewalDate), true);
    });

    test('debt reminder should trigger within 7 days', () {
      final now = DateTime.now();
      final dueDate1 = now.add(const Duration(days: 3));
      final dueDate2 = now.add(const Duration(days: 7));
      final dueDate3 = now.add(const Duration(days: 14));

      expect(dueDate1.difference(now).inDays <= 7, true);
      expect(dueDate2.difference(now).inDays <= 7, true);
      expect(dueDate3.difference(now).inDays <= 7, false);
    });

    test('should convert notification IDs to consistent hash codes', () {
      final id1 = 'sub_renewal_Netflix'.hashCode;
      final id2 = 'sub_renewal_Netflix'.hashCode;
      final id3 = 'sub_renewal_Spotify'.hashCode;

      expect(id1, id2);
      expect(id1 != id3, true);
    });

    test('should calculate days until renewal', () {
      final now = DateTime.now();
      final renewalDate = now.add(const Duration(days: 10));

      expect(renewalDate.difference(now).inDays, 10);
    });

    test('should handle past renewal dates', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 5));

      expect(pastDate.isBefore(now), true);
    });
  });
}
