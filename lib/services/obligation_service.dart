import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/api_service.dart';

class ObligationService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getObligationsSummary() async {
    try {
      return await _apiService.getObligationsSummary();
    } catch (e) {
      print('Error fetching obligations summary: $e');
      return {'monthlyTotal': 0.0, 'totalDebt': 0.0, 'obligationsCount': 0};
    }
  }

  Future<List<FinancialObligation>> getUpcomingObligations({
    int days = 7,
  }) async {
    try {
      final obligations = await _apiService.getUpcomingObligations(days: days);
      return obligations.map((data) => _parseObligation(data)).toList();
    } catch (e) {
      print('Error fetching upcoming obligations: $e');
      return [];
    }
  }

  Future<List<FinancialObligation>> getObligations({String? type}) async {
    try {
      final obligations = await _apiService.getObligations(type: type);
      return obligations.map((data) => _parseObligation(data)).toList();
    } catch (e) {
      print('Error fetching obligations: $e');
      return [];
    }
  }

  Future<DebtSummary> getDebtSummary() async {
    try {
      final obligations = await _apiService.getObligations(type: 'debt');
      final debts = obligations.map((data) => _parseObligation(data)).toList();

      double totalDebt = 0.0;
      double monthlyPayments = 0.0;

      for (var debt in debts) {
        totalDebt += debt.currentBalance ?? 0.0;
        monthlyPayments += debt.monthlyAmount;
      }

      return DebtSummary(
        debts: debts,
        totalDebt: totalDebt,
        monthlyPayments: monthlyPayments,
      );
    } catch (e) {
      print('Error fetching debt summary: $e');
      return DebtSummary(debts: [], totalDebt: 0.0, monthlyPayments: 0.0);
    }
  }

  Future<List<FinancialObligation>> getSubscriptions() async {
    try {
      final obligations = await _apiService.getObligations(
        type: 'subscription',
      );
      return obligations.map((data) => _parseObligation(data)).toList();
    } catch (e) {
      print('Error fetching subscriptions: $e');
      return [];
    }
  }

  Future<String> createObligation(Map<String, dynamic> obligationData) async {
    final response = await _apiService.createObligation(obligationData);
    return response['obligation_id'] ?? '';
  }

  Future<void> updateObligation(
    String obligationId,
    Map<String, dynamic> obligationData,
  ) async {
    await _apiService.updateObligation(obligationId, obligationData);
  }

  Future<void> deleteObligation(String obligationId) async {
    await _apiService.deleteObligation(obligationId);
  }

  Future<void> recordPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    await _apiService.recordObligationPayment(obligationId, paymentData);
  }

  FinancialObligation _parseObligation(Map<String, dynamic> data) {
    final typeStr = data['type_232143'] as String?;
    ObligationType type = ObligationType.bill;
    if (typeStr == 'debt') {
      type = ObligationType.debt;
    } else if (typeStr == 'subscription') {
      type = ObligationType.subscription;
    }

    DateTime? dueDate;
    final dueDateStr = data['due_date_232143'];
    if (dueDateStr != null) {
      try {
        // due_date is stored as day of month (1-31)
        final dayOfMonth = int.parse(dueDateStr.toString());
        final now = DateTime.now();
        dueDate = DateTime(now.year, now.month, dayOfMonth);

        // If the date has passed this month, use next month
        if (dueDate.isBefore(now)) {
          dueDate = DateTime(now.year, now.month + 1, dayOfMonth);
        }
      } catch (e) {
        print('Error parsing due date: $e');
      }
    }

    final daysUntilDue =
        data['days_until_due'] as int? ??
        (dueDate != null ? dueDate.difference(DateTime.now()).inDays : 0);

    // Helper function to safely parse decimal values
    double? parseDecimal(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return FinancialObligation(
      id: data['obligation_id_232143']?.toString() ?? '',
      name: data['name_232143']?.toString() ?? '',
      monthlyAmount: parseDecimal(data['monthly_amount_232143']) ?? 0.0,
      dueDate: dueDate ?? DateTime.now(),
      type: type,
      daysUntilDue: daysUntilDue,
      category: data['category_232143']?.toString(),
      originalAmount: parseDecimal(data['original_amount_232143']),
      currentBalance: parseDecimal(data['current_balance_232143']),
      interestRate: parseDecimal(data['interest_rate_232143']),
      isSubscription:
          data['is_subscription_232143'] == 1 ||
          data['is_subscription_232143'] == true,
      subscriptionCycle: data['subscription_cycle_232143']?.toString(),
      minimumPayment: parseDecimal(data['minimum_payment_232143']),
      payoffStrategy: data['payoff_strategy_232143']?.toString(),
    );
  }
}
