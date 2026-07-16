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
  final String? debtType;
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
    this.debtType,
    required this.daysUntilDue,
  });

  String get formattedDueDate {
    return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthly_amount': monthlyAmount,
      'due_date': dueDate.toIso8601String(),
      'type': type.name,
      'category': category,
      'original_amount': originalAmount,
      'current_balance': currentBalance,
      'interest_rate': interestRate,
      'is_subscription': isSubscription,
      'subscription_cycle': subscriptionCycle,
      'minimum_payment': minimumPayment,
      'payoff_strategy': payoffStrategy,
      'debt_type': debtType,
      'days_until_due': daysUntilDue,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'obligation_id_232143': id,
      'name_232143': name,
      'amount_232143': monthlyAmount,
      'due_date_232143': dueDate.toIso8601String().split('T')[0],
      'type_232143': type.name,
      'category_232143': category,
      'original_amount_232143': originalAmount,
      'current_balance_232143': currentBalance,
      'interest_rate_232143': interestRate,
      'is_subscription_232143': isSubscription ? 1 : 0,
      'subscription_cycle_232143': subscriptionCycle,
      'minimum_payment_232143': minimumPayment,
      'payoff_strategy_232143': payoffStrategy,
      'debt_type_232143': debtType,
    };
  }

  factory FinancialObligation.fromJson(Map<String, dynamic> json) {
    return FinancialObligation(
      id:
          json['id']?.toString() ??
          json['obligation_id_232143']?.toString() ??
          '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      monthlyAmount:
          (json['monthly_amount'] as num?)?.toDouble() ??
          (json['monthly_amount_232143'] as num?)?.toDouble() ??
          0.0,
      dueDate:
          _parseDate(json['due_date']) ??
          _parseDate(json['due_date_232143']) ??
          DateTime.now(),
      type: _parseObligationType(
        json['type']?.toString() ?? json['type_232143']?.toString(),
      ),
      category:
          json['category']?.toString() ?? json['category_232143']?.toString(),
      originalAmount:
          (json['original_amount'] as num?)?.toDouble() ??
          (json['original_amount_232143'] as num?)?.toDouble(),
      currentBalance:
          (json['current_balance'] as num?)?.toDouble() ??
          (json['current_balance_232143'] as num?)?.toDouble(),
      interestRate:
          (json['interest_rate'] as num?)?.toDouble() ??
          (json['interest_rate_232143'] as num?)?.toDouble(),
      isSubscription:
          json['is_subscription'] == true ||
          json['is_subscription'] == 1 ||
          json['is_subscription_232143'] == 1 ||
          json['is_subscription_232143'] == true,
      subscriptionCycle:
          json['subscription_cycle']?.toString() ??
          json['subscription_cycle_232143']?.toString(),
      minimumPayment:
          (json['minimum_payment'] as num?)?.toDouble() ??
          (json['minimum_payment_232143'] as num?)?.toDouble(),
      payoffStrategy:
          json['payoff_strategy']?.toString() ??
          json['payoff_strategy_232143']?.toString(),
      debtType:
          json['debt_type']?.toString() ??
          json['debt_type_232143']?.toString(),
      daysUntilDue: (json['days_until_due'] as num?)?.toInt() ?? 0,
    );
  }

  factory FinancialObligation.fromMap(Map<String, dynamic> map) {
    String? typeStr;
    if (map['type_232143'] != null) {
      typeStr = map['type_232143'].toString();
    } else if (map['type'] != null) {
      typeStr = map['type'].toString();
    }

    ObligationType type = ObligationType.bill;
    if (typeStr == 'debt') {
      type = ObligationType.debt;
    } else if (typeStr == 'subscription') {
      type = ObligationType.subscription;
    }

    DateTime? dueDate;
    final dueDateStr = map['due_date_232143'] ?? map['due_date'];
    if (dueDateStr != null) {
      try {
        final dayOfMonth = int.parse(dueDateStr.toString());
        final now = DateTime.now();
        dueDate = DateTime(now.year, now.month, dayOfMonth);
        if (dueDate.isBefore(now)) {
          dueDate = DateTime(now.year, now.month + 1, dayOfMonth);
        }
      } catch (e) {
        dueDate = _parseDate(dueDateStr.toString());
      }
    }

    double? parseDecimal(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return FinancialObligation(
      id: map['obligation_id_232143']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? '',
      monthlyAmount: parseDecimal(map['monthly_amount_232143']) ??
          parseDecimal(map['amount_232143']) ??
          0.0,
      dueDate: dueDate ?? DateTime.now(),
      type: type,
      daysUntilDue:
          map['days_until_due'] as int? ??
          (dueDate != null ? dueDate.difference(DateTime.now()).inDays : 0),
      category: map['category_232143']?.toString(),
      originalAmount: parseDecimal(map['original_amount_232143']),
      currentBalance: parseDecimal(map['current_balance_232143']),
      interestRate: parseDecimal(map['interest_rate_232143']),
      isSubscription:
          map['is_subscription_232143'] == 1 ||
          map['is_subscription_232143'] == true,
      subscriptionCycle: map['subscription_cycle_232143']?.toString(),
      minimumPayment: parseDecimal(map['minimum_payment_232143']),
      payoffStrategy: map['payoff_strategy_232143']?.toString(),
      debtType: map['debt_type_232143']?.toString(),
    );
  }

  static ObligationType _parseObligationType(String? value) {
    if (value == null) return ObligationType.bill;
    return ObligationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ObligationType.bill,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
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
