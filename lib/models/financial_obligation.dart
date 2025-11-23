enum ObligationType { bill, debt, subscription }

class FinancialObligation {
  final String id;
  final String name;
  final double monthlyAmount;
  final DateTime dueDate;
  final ObligationType type;
  final String? category;
  final double? originalAmount;
  final double? currentBalance;
  final double? interestRate;
  final bool isSubscription;
  final String? subscriptionCycle;
  final double? minimumPayment;
  final String? payoffStrategy;
  final int daysUntilDue;

  FinancialObligation({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.dueDate,
    required this.type,
    this.category,
    this.originalAmount,
    this.currentBalance,
    this.interestRate,
    this.isSubscription = false,
    this.subscriptionCycle,
    this.minimumPayment,
    this.payoffStrategy,
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
