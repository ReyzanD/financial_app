class GoalModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String
  goalType; // emergency_fund, vacation, investment, debt_payment, education, vehicle, house, wedding, other
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime targetDate;
  final bool isCompleted;
  final DateTime? completedDate;
  final int priority; // 1-5
  final double? monthlyTarget;
  final bool autoDeduct;
  final double? deductPercentage;
  final double? recommendedMonthlySaving;
  final double? feasibilityScore;
  final double progressPercentage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.goalType,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.startDate,
    required this.targetDate,
    this.isCompleted = false,
    this.completedDate,
    this.priority = 3,
    this.monthlyTarget,
    this.autoDeduct = false,
    this.deductPercentage,
    this.recommendedMonthlySaving,
    this.feasibilityScore,
    this.progressPercentage = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  double get remaining => (targetAmount - currentAmount).clamp(0, targetAmount);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'goal_type': goalType,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'start_date': startDate.toIso8601String().split('T')[0],
      'target_date': targetDate.toIso8601String().split('T')[0],
      'is_completed': isCompleted,
      'completed_date': completedDate?.toIso8601String().split('T')[0],
      'priority': priority,
      'monthly_target': monthlyTarget,
      'auto_deduct': autoDeduct,
      'deduct_percentage': deductPercentage,
      'recommended_monthly_saving': recommendedMonthlySaving,
      'feasibility_score': feasibilityScore,
      'progress_percentage': progressPercentage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_id_232143': id,
      'user_id_232143': userId,
      'name_232143': name,
      'description_232143': description,
      'goal_type_232143': goalType,
      'target_amount_232143': targetAmount,
      'current_amount_232143': currentAmount,
      'start_date_232143': startDate.toIso8601String().split('T')[0],
      'target_date_232143': targetDate.toIso8601String().split('T')[0],
      'is_completed_232143': isCompleted ? 1 : 0,
      'completed_date_232143': completedDate?.toIso8601String().split('T')[0],
      'priority_232143': priority,
      'monthly_target_232143': monthlyTarget,
      'auto_deduct_232143': autoDeduct ? 1 : 0,
      'deduct_percentage_232143': deductPercentage,
      'recommended_monthly_saving_232143': recommendedMonthlySaving,
      'feasibility_score_232143': feasibilityScore,
      'progress_percentage_232143': progressPercentage,
      'created_at_232143': createdAt.toIso8601String(),
      'updated_at_232143': updatedAt?.toIso8601String(),
    };
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id']?.toString() ?? json['goal_id_232143']?.toString() ?? '',
      userId:
          json['user_id']?.toString() ??
          json['user_id_232143']?.toString() ??
          '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      description:
          json['description']?.toString() ??
          json['description_232143']?.toString(),
      goalType:
          json['goal_type']?.toString() ??
          json['goal_type_232143']?.toString() ??
          'other',
      targetAmount:
          (json['target_amount'] as num?)?.toDouble() ??
          (json['target_amount_232143'] as num?)?.toDouble() ??
          0.0,
      currentAmount:
          (json['current_amount'] as num?)?.toDouble() ??
          (json['current_amount_232143'] as num?)?.toDouble() ??
          0.0,
      startDate:
          json['start_date'] != null
              ? DateTime.parse(json['start_date'].toString())
              : json['start_date_232143'] != null
              ? DateTime.parse(json['start_date_232143'].toString())
              : DateTime.now(),
      targetDate:
          json['target_date'] != null
              ? DateTime.parse(json['target_date'].toString())
              : json['target_date_232143'] != null
              ? DateTime.parse(json['target_date_232143'].toString())
              : DateTime.now(),
      isCompleted:
          _parseBool(json['is_completed']) ??
          _parseBool(json['is_completed_232143']) ??
          false,
      completedDate:
          json['completed_date'] != null
              ? DateTime.parse(json['completed_date'].toString())
              : json['completed_date_232143'] != null
              ? DateTime.parse(json['completed_date_232143'].toString())
              : null,
      priority:
          (json['priority'] as num?)?.toInt() ??
          (json['priority_232143'] as num?)?.toInt() ??
          3,
      monthlyTarget:
          (json['monthly_target'] as num?)?.toDouble() ??
          (json['monthly_target_232143'] as num?)?.toDouble(),
      autoDeduct:
          _parseBool(json['auto_deduct']) ??
          _parseBool(json['auto_deduct_232143']) ??
          false,
      deductPercentage:
          (json['deduct_percentage'] as num?)?.toDouble() ??
          (json['deduct_percentage_232143'] as num?)?.toDouble(),
      recommendedMonthlySaving:
          (json['recommended_monthly_saving'] as num?)?.toDouble() ??
          (json['recommended_monthly_saving_232143'] as num?)?.toDouble(),
      feasibilityScore:
          (json['feasibility_score'] as num?)?.toDouble() ??
          (json['feasibility_score_232143'] as num?)?.toDouble(),
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ??
          (json['progress_percentage_232143'] as num?)?.toDouble() ??
          0.0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : json['created_at_232143'] != null
              ? DateTime.parse(json['created_at_232143'].toString())
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'].toString())
              : json['updated_at_232143'] != null
              ? DateTime.parse(json['updated_at_232143'].toString())
              : null,
    );
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel.fromJson(map);
  }

  GoalModel copyWith({
    String? name,
    String? description,
    String? goalType,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? completedDate,
    int? priority,
    double? monthlyTarget,
    bool? autoDeduct,
    double? deductPercentage,
    double? recommendedMonthlySaving,
    double? feasibilityScore,
    double? progressPercentage,
  }) {
    return GoalModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      priority: priority ?? this.priority,
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      autoDeduct: autoDeduct ?? this.autoDeduct,
      deductPercentage: deductPercentage ?? this.deductPercentage,
      recommendedMonthlySaving:
          recommendedMonthlySaving ?? this.recommendedMonthlySaving,
      feasibilityScore: feasibilityScore ?? this.feasibilityScore,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    return null;
  }

  static const List<String> goalTypes = [
    'emergency_fund',
    'vacation',
    'investment',
    'debt_payment',
    'education',
    'vehicle',
    'house',
    'wedding',
    'other',
  ];
}
