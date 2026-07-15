import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/subscription_tracker_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class FinancialCalendarService {
  final TransactionDataService _transactionData;
  final SubscriptionTrackerService _subscriptionService;

  FinancialCalendarService({
    TransactionDataService? transactionData,
    SubscriptionTrackerService? subscriptionService,
  }) : _transactionData = transactionData ?? getIt<TransactionDataService>(),
       _subscriptionService =
            subscriptionService ?? getIt<SubscriptionTrackerService>();

  Future<List<Map<String, dynamic>>> getMonthEvents(int year, int month) async {
    final events = <Map<String, dynamic>>[];

    try {
      // UTC-safe for offline use — the app stores dates without timezone info,
      // so using UTC avoids DST boundary inconsistencies
      final startDate = DateTime.utc(year, month, 1);
      final endDate = DateTime.utc(year, month + 1, 0);

      final transactionsData = await _transactionData.getTransactions(
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );

      final transactions =
          List<Map<String, dynamic>>.from(
            transactionsData['transactions'] ?? [],
          );
      for (final transaction in transactions) {
        final dateStr =
            transaction['transaction_date_232143']?.toString() ??
            transaction['transaction_date']?.toString() ??
            '';
        if (dateStr.isNotEmpty) {
          try {
            final date = DateTime.parse(dateStr);
            events.add({
              'date': date,
              'type': 'transaction',
              'title':
                  transaction['description_232143']?.toString() ??
                  transaction['description']?.toString() ??
                  'Transaction',
              'amount':
                  (transaction['amount_232143'] as num?)?.toDouble() ??
                  (transaction['amount'] as num?)?.toDouble() ??
                  0.0,
              'transaction_type':
                  transaction['type_232143']?.toString() ??
                  transaction['type']?.toString() ??
                  'expense',
              'category': transaction['category_name']?.toString() ?? '',
            });
          } catch (e) {
            // Skip invalid dates
          }
        }
      }

      final subscriptions = await _subscriptionService.getSubscriptions();
      for (var sub in subscriptions) {
        if (sub.nextRenewal != null &&
            sub.nextRenewal!.year == year &&
            sub.nextRenewal!.month == month) {
          events.add({
            'date': sub.nextRenewal!,
            'type': 'subscription',
            'title': '${sub.name} Renewal',
            'amount': sub.cost,
            'transaction_type': 'expense',
            'category': sub.category,
          });
        }
      }

      events.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );
    } catch (e) {
      LoggerService.error('Error getting calendar events', error: e);
    }

    return events;
  }

  Future<Map<String, dynamic>> getDaySummary(DateTime date) async {
    final events = await getMonthEvents(date.year, date.month);
    final dayEvents =
        events.where((e) {
          final eventDate = e['date'] as DateTime;
          return eventDate.year == date.year &&
              eventDate.month == date.month &&
              eventDate.day == date.day;
        }).toList();

    double totalIncome = 0;
    double totalExpense = 0;

    for (var event in dayEvents) {
      if (event['transaction_type'] == 'income') {
        totalIncome += event['amount'] as double;
      } else {
        totalExpense += event['amount'] as double;
      }
    }

    return {
      'date': date,
      'events': dayEvents,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'net': totalIncome - totalExpense,
      'event_count': dayEvents.length,
    };
  }

  Future<List<Map<String, dynamic>>> getUpcomingEvents({
    int daysAhead = 7,
  }) async {
    final now = DateTime.now();
    final events = await getMonthEvents(now.year, now.month);

    if (now.month < 12) {
      final nextMonthEvents = await getMonthEvents(now.year, now.month + 1);
      events.addAll(nextMonthEvents);
    }

    final upcoming =
        events.where((e) {
          final eventDate = e['date'] as DateTime;
          final diff = eventDate.difference(now).inDays;
          return diff >= 0 && diff <= daysAhead;
        }).toList();

    upcoming.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return upcoming;
  }

  Future<Map<int, int>> getMonthlyHeatMap(int year, int month) async {
    final events = await getMonthEvents(year, month);
    final heatMap = <int, int>{};

    for (var event in events) {
      final date = event['date'] as DateTime;
      final day = date.day;
      if (event['transaction_type'] == 'expense') {
        heatMap[day] = (heatMap[day] ?? 0) + 1;
      }
    }

    return heatMap;
  }
}
