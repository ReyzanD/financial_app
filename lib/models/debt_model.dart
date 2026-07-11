import 'dart:math' as math;

class DebtModel {
  final String id;
  final String name;
  final double originalAmount;
  final double currentBalance;
  final double interestRate;
  final String type;
  final DateTime startDate;
  final DateTime? dueDate;
  final double monthlyPayment;
  final String? creditorName;
  final String? notes;
  final DateTime createdAt;

  DebtModel({
    required this.id,
    required this.name,
    required this.originalAmount,
    required this.currentBalance,
    this.interestRate = 0,
    required this.type,
    required this.startDate,
    this.dueDate,
    this.monthlyPayment = 0,
    this.creditorName,
    this.notes,
    required this.createdAt,
  });

  int get monthsRemaining {
    if (monthlyPayment <= 0 || interestRate <= 0) return 0;
    final monthlyRate = interestRate / 100 / 12;
    if (monthlyRate == 0) return (currentBalance / monthlyPayment).ceil();
    final n =
        -(math.log(1 - (currentBalance * monthlyRate / monthlyPayment)) /
            math.log(1 + monthlyRate));
    return n.isFinite && n > 0 ? n.ceil() : 0;
  }

  double get totalInterest {
    if (monthlyPayment <= 0) return 0;
    return (monthsRemaining * monthlyPayment) - currentBalance;
  }

  DateTime get payoffDateEstimate {
    return startDate.add(Duration(days: monthsRemaining * 30));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'original_amount': originalAmount,
      'current_balance': currentBalance,
      'interest_rate': interestRate,
      'type': type,
      'start_date': startDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'monthly_payment': monthlyPayment,
      'creditor_name': creditorName,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'debt_id_232143': id,
      'name': name,
      'original_amount': originalAmount,
      'current_balance': currentBalance,
      'interest_rate': interestRate,
      'type': type,
      'start_date': startDate.toIso8601String().split('T')[0],
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'monthly_payment': monthlyPayment,
      'creditor_name': creditorName,
      'notes': notes,
      'created_at': createdAt.toIso8601String().split('T')[0],
    };
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id']?.toString() ?? json['debt_id_232143']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      originalAmount:
          (json['original_amount'] as num?)?.toDouble() ??
          (json['original_amount_232143'] as num?)?.toDouble() ??
          0.0,
      currentBalance:
          (json['current_balance'] as num?)?.toDouble() ??
          (json['current_balance_232143'] as num?)?.toDouble() ??
          0.0,
      interestRate:
          (json['interest_rate'] as num?)?.toDouble() ??
          (json['interest_rate_232143'] as num?)?.toDouble() ??
          0,
      type:
          json['type']?.toString() ??
          json['type_232143']?.toString() ??
          'other',
      startDate:
          _parseDate(json['start_date']) ??
          _parseDate(json['start_date_232143']) ??
          DateTime.now(),
      dueDate:
          _parseDate(json['due_date']) ?? _parseDate(json['due_date_232143']),
      monthlyPayment:
          (json['monthly_payment'] as num?)?.toDouble() ??
          (json['monthly_payment_232143'] as num?)?.toDouble() ??
          0,
      creditorName:
          json['creditor_name']?.toString() ??
          json['creditor_name_232143']?.toString(),
      notes: json['notes']?.toString() ?? json['notes_232143']?.toString(),
      createdAt:
          _parseDate(json['created_at']) ??
          _parseDate(json['created_at_232143']) ??
          DateTime.now(),
    );
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['debt_id_232143']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? map['name']?.toString() ?? '',
      originalAmount:
          (map['original_amount_232143'] as num?)?.toDouble() ??
          (map['original_amount'] as num?)?.toDouble() ??
          0.0,
      currentBalance:
          (map['current_balance_232143'] as num?)?.toDouble() ??
          (map['current_balance'] as num?)?.toDouble() ??
          0.0,
      interestRate:
          (map['interest_rate_232143'] as num?)?.toDouble() ??
          (map['interest_rate'] as num?)?.toDouble() ??
          0,
      type:
          map['type_232143']?.toString() ?? map['type']?.toString() ?? 'other',
      startDate:
          _parseDate(map['start_date_232143']) ??
          _parseDate(map['start_date']) ??
          DateTime.now(),
      dueDate:
          _parseDate(map['due_date_232143']) ?? _parseDate(map['due_date']),
      monthlyPayment:
          (map['monthly_payment_232143'] as num?)?.toDouble() ??
          (map['monthly_payment'] as num?)?.toDouble() ??
          0,
      creditorName:
          map['creditor_name_232143']?.toString() ??
          map['creditor_name']?.toString(),
      notes: map['notes_232143']?.toString() ?? map['notes']?.toString(),
      createdAt:
          _parseDate(map['created_at_232143']) ??
          _parseDate(map['created_at']) ??
          DateTime.now(),
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

  static List<String> get types => [
    'personal',
    'mortgage',
    'student',
    'credit_card',
    'car',
    'business',
    'other',
  ];
}
