enum ObligationType { bill, debt, subscription }

class FinancialObligation {
  final String id;
  final String name;
  final double monthlyAmount;
  final DateTime dueDate;
  final ObligationType type;
  final double? currentBalance;
  final bool isSubscription;
  final String? subscriptionCycle;
  final int daysUntilDue;

  FinancialObligation({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.dueDate,
    required this.type,
    this.currentBalance,
    this.isSubscription = false,
    this.subscriptionCycle,
    required this.daysUntilDue,
  });

  String get formattedDueDate {
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }
}

class DebtSummary {
  final List<FinancialObligation> debts;
  final double totalDebt;
  final double monthlyPayments;

  DebtSummary({
    required this.debts,
    required this.totalDebt,
    required this.monthlyPayments,
  });
}
