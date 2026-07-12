/// Budget Entity (Domain Layer)
class BudgetEntity {
  final String id;
  final String categoryId;
  final double amount;
  final double spent;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.spent,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  factory BudgetEntity.fromJson(Map<String, dynamic> json) {
    return BudgetEntity(
      id:
          json['budget_id_232143']?.toString() ??
          json['budget_id']?.toString() ??
          json['id']?.toString() ??
          '',
      categoryId:
          json['category_id_232143']?.toString() ??
          json['category_id']?.toString() ??
          '',
      amount:
          (json['amount_232143'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0.0,
      spent:
          (json['spent_amount_232143'] as num?)?.toDouble() ??
          (json['spent_amount'] as num?)?.toDouble() ??
          (json['spent'] as num?)?.toDouble() ??
          0.0,
      startDate:
          json['period_start_232143'] != null
              ? DateTime.parse(json['period_start_232143'].toString())
              : json['start_date'] != null
              ? DateTime.parse(json['start_date'].toString())
              : DateTime.now(),
      endDate:
          json['period_end_232143'] != null
              ? DateTime.parse(json['period_end_232143'].toString())
              : json['end_date'] != null
              ? DateTime.parse(json['end_date'].toString())
              : DateTime.now(),
      isActive:
          json['is_active_232143'] != null
              ? json['is_active_232143'] == 1
              : json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'spent': spent,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
    };
  }

  double get remaining => amount - spent;
  double get percentageUsed => amount > 0 ? (spent / amount) * 100 : 0.0;
  bool get isOverBudget => spent > amount;
}
