/// Budget Model
class BudgetModel {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final double spent;
  final double remaining;
  final String period;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool rolloverEnabled;
  final int alertThreshold;
  final bool isActive;
  final String? recommendationReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    this.spent = 0.0,
    this.remaining = 0.0,
    this.period = 'monthly',
    required this.periodStart,
    required this.periodEnd,
    this.rolloverEnabled = false,
    this.alertThreshold = 80,
    this.isActive = true,
    this.recommendationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// From DB map (suffixed keys)
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: (map['budget_id_232143'] ?? map['budget_id'] ?? map['id'] ?? '').toString(),
      userId: (map['user_id_232143'] ?? map['user_id'] ?? '').toString(),
      categoryId: (map['category_id_232143'] ?? map['category_id'] ?? '').toString(),
      amount: (map['amount_232143'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0.0,
      spent:
          (map['spent_amount_232143'] as num?)?.toDouble() ??
          (map['spent_amount'] as num?)?.toDouble() ??
          (map['spent'] as num?)?.toDouble() ??
          0.0,
      remaining:
          (map['remaining_amount_232143'] as num?)?.toDouble() ??
          (map['remaining_amount'] as num?)?.toDouble() ??
          (map['remaining'] as num?)?.toDouble() ??
          0.0,
      period: (map['period_232143'] ?? map['period'] ?? 'monthly').toString(),
      periodStart:
          map['period_start_232143'] != null
              ? DateTime.parse(map['period_start_232143'].toString())
              : map['period_start'] != null
              ? DateTime.parse(map['period_start'].toString())
              : DateTime.now(),
      periodEnd:
          map['period_end_232143'] != null
              ? DateTime.parse(map['period_end_232143'].toString())
              : map['period_end'] != null
              ? DateTime.parse(map['period_end'].toString())
              : DateTime.now(),
      rolloverEnabled:
          (map['rollover_enabled_232143'] ?? map['rollover_enabled'] ?? 0) == 1 ||
          (map['rollover_enabled_232143'] ?? map['rollover_enabled'] ?? false) == true,
      alertThreshold:
          (map['alert_threshold_232143'] as num?)?.toInt() ?? (map['alert_threshold'] as num?)?.toInt() ?? 80,
      isActive: map['is_active_232143'] != null ? map['is_active_232143'] == 1 : (map['is_active'] as bool?) ?? true,
      recommendationReason: (map['recommendation_reason_232143'] ?? map['recommendation_reason'])?.toString(),
      createdAt:
          map['created_at_232143'] != null ? DateTime.parse(map['created_at_232143'].toString()) : DateTime.now(),
      updatedAt:
          map['updated_at_232143'] != null ? DateTime.parse(map['updated_at_232143'].toString()) : DateTime.now(),
    );
  }

  /// To DB map (suffixed keys for inserts)
  Map<String, dynamic> toMap() {
    return {
      'budget_id_232143': id,
      'user_id_232143': userId,
      'category_id_232143': categoryId,
      'amount_232143': amount,
      'spent_amount_232143': spent,
      'remaining_amount_232143': amount - spent,
      'period_232143': period,
      'period_start_232143': periodStart.toIso8601String(),
      'period_end_232143': periodEnd.toIso8601String(),
      'rollover_enabled_232143': rolloverEnabled ? 1 : 0,
      'alert_threshold_232143': alertThreshold,
      'is_active_232143': isActive ? 1 : 0,
      if (recommendationReason != null) 'recommendation_reason_232143': recommendationReason,
      'created_at_232143': createdAt.toIso8601String(),
      'updated_at_232143': updatedAt.toIso8601String(),
    };
  }

  /// Clean JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'spent': spent,
      'remaining': amount - spent,
      'period': period,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'rollover_enabled': rolloverEnabled,
      'alert_threshold': alertThreshold,
      'is_active': isActive,
      'recommendation_reason': recommendationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Computed helpers
  double get remainingAmount => amount - spent;
  double get percentageUsed => amount > 0 ? (spent / amount) * 100 : 0.0;
  bool get isOverBudget => spent > amount;

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    double? amount,
    double? spent,
    double? remaining,
    String? period,
    DateTime? periodStart,
    DateTime? periodEnd,
    bool? rolloverEnabled,
    int? alertThreshold,
    bool? isActive,
    String? recommendationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      remaining: remaining ?? this.remaining,
      period: period ?? this.period,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      recommendationReason: recommendationReason ?? this.recommendationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
