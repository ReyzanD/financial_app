/// Goal Entity (Domain Layer)
class GoalEntity {
  final String id;
  final String name;
  final String description;
  final String goalType;
  final double targetAmount;
  final double currentAmount;
  final String? categoryId;
  final String? iconName;
  final int priority;
  final DateTime targetDate;
  final DateTime createdAt;
  final bool isCompleted;

  GoalEntity({
    required this.id,
    required this.name,
    this.description = '',
    this.goalType = 'custom',
    required this.targetAmount,
    required this.currentAmount,
    this.categoryId,
    this.iconName,
    this.priority = 0,
    required this.targetDate,
    DateTime? createdAt,
    this.isCompleted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GoalEntity.fromJson(Map<String, dynamic> json) {
    return GoalEntity(
      id: json['goal_id_232143']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name_232143']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description_232143']?.toString() ?? json['description']?.toString() ?? '',
      goalType: json['goal_type_232143']?.toString() ?? json['goal_type']?.toString() ?? 'custom',
      targetAmount: (json['target_amount_232143'] ?? json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['current_amount_232143'] ?? json['current_amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['category_id_232143']?.toString() ?? json['category_id']?.toString(),
      iconName: json['icon_232143']?.toString() ?? json['icon']?.toString(),
      priority: (json['priority_232143'] ?? json['priority'] as int?) ?? 0,
      targetDate:
          json['target_date_232143'] != null
              ? DateTime.parse(json['target_date_232143'].toString())
              : json['target_date'] != null
              ? DateTime.parse(json['target_date'].toString())
              : DateTime.now().add(const Duration(days: 30)),
      createdAt:
          json['created_at_232143'] != null ? DateTime.parse(json['created_at_232143'].toString()) : DateTime.now(),
      isCompleted:
          json['is_completed_232143'] != null
              ? (json['is_completed_232143'] as num?) == 1
              : json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_id_232143': id,
      'name_232143': name,
      'description_232143': description,
      'goal_type_232143': goalType,
      'target_amount_232143': targetAmount,
      'current_amount_232143': currentAmount,
      'category_id_232143': categoryId,
      'icon_232143': iconName,
      'priority_232143': priority,
      'target_date_232143': targetDate.toIso8601String(),
      'created_at_232143': createdAt.toIso8601String(),
      'is_completed_232143': isCompleted ? 1 : 0,
    };
  }

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);
}
