import 'package:financial_app/models/financial_obligation.dart';

class ObligationService {
  Future<Map<String, dynamic>> getObligationsSummary() async {
    // Mock data
    await Future.delayed(Duration(seconds: 1));
    return {'monthlyTotal': 2500000.0, 'totalDebt': 15000000.0};
  }

  Future<List<FinancialObligation>> getUpcomingObligations() async {
    // Mock data
    await Future.delayed(Duration(seconds: 1));
    return [
      FinancialObligation(
        id: '1',
        name: 'Listrik',
        monthlyAmount: 150000,
        dueDate: DateTime.now().add(Duration(days: 5)),
        type: ObligationType.bill,
        daysUntilDue: 5,
      ),
      FinancialObligation(
        id: '2',
        name: 'Internet',
        monthlyAmount: 500000,
        dueDate: DateTime.now().add(Duration(days: 10)),
        type: ObligationType.subscription,
        isSubscription: true,
        subscriptionCycle: 'Bulanan',
        daysUntilDue: 10,
      ),
      FinancialObligation(
        id: '3',
        name: 'Kredit Motor',
        monthlyAmount: 800000,
        dueDate: DateTime.now().add(Duration(days: 15)),
        type: ObligationType.debt,
        currentBalance: 5000000,
        daysUntilDue: 15,
      ),
    ];
  }

  Future<DebtSummary> getDebtSummary() async {
    // Mock data
    await Future.delayed(Duration(seconds: 1));
    final debts = [
      FinancialObligation(
        id: '3',
        name: 'Kredit Motor',
        monthlyAmount: 800000,
        dueDate: DateTime.now().add(Duration(days: 15)),
        type: ObligationType.debt,
        currentBalance: 5000000,
        daysUntilDue: 15,
      ),
      FinancialObligation(
        id: '4',
        name: 'Kredit Rumah',
        monthlyAmount: 2000000,
        dueDate: DateTime.now().add(Duration(days: 20)),
        type: ObligationType.debt,
        currentBalance: 100000000,
        daysUntilDue: 20,
      ),
    ];

    return DebtSummary(
      debts: debts,
      totalDebt: 105000000.0,
      monthlyPayments: 2800000.0,
    );
  }

  Future<List<FinancialObligation>> getSubscriptions() async {
    // Mock data
    await Future.delayed(Duration(seconds: 1));
    return [
      FinancialObligation(
        id: '2',
        name: 'Internet',
        monthlyAmount: 500000,
        dueDate: DateTime.now().add(Duration(days: 10)),
        type: ObligationType.subscription,
        isSubscription: true,
        subscriptionCycle: 'Bulanan',
        daysUntilDue: 10,
      ),
      FinancialObligation(
        id: '5',
        name: 'Netflix',
        monthlyAmount: 65000,
        dueDate: DateTime.now().add(Duration(days: 25)),
        type: ObligationType.subscription,
        isSubscription: true,
        subscriptionCycle: 'Bulanan',
        daysUntilDue: 25,
      ),
    ];
  }
}
