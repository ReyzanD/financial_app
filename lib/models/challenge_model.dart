class ChallengeModel {
  final String id;
  final String name;
  final String type;
  final double target;
  final double currentProgress;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int streak;
  final int bestStreak;
  final DateTime createdAt;

  ChallengeModel({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    this.currentProgress = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.streak = 0,
    this.bestStreak = 0,
    required this.createdAt,
  });

  double get progressPercentage => target > 0 ? (currentProgress / target) * 100 : 0;

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  bool get isCompleted => currentProgress >= target;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'target': target,
      'current_progress': currentProgress,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'streak': streak,
      'best_streak': bestStreak,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'target_amount': target,
      'current_amount': currentProgress,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'is_active': isActive ? 1 : 0,
      'streak_days': streak,
    };
  }

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id']?.toString() ?? json['challenge_id_232143']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      type: json['type']?.toString() ?? json['type_232143']?.toString() ?? 'no_spend',
      target: (json['target'] as num?)?.toDouble() ?? (json['target_amount_232143'] as num?)?.toDouble() ?? 0.0,
      currentProgress:
          (json['current_progress'] as num?)?.toDouble() ?? (json['current_amount_232143'] as num?)?.toDouble() ?? 0.0,
      startDate: _parseDate(json['start_date']) ?? _parseDate(json['start_date_232143']) ?? DateTime.now(),
      endDate:
          _parseDate(json['end_date']) ??
          _parseDate(json['end_date_232143']) ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: _parseBool(json['is_active']) ?? _parseBool(json['is_active_232143']) ?? true,
      streak: (json['streak'] as num?)?.toInt() ?? (json['streak_days_232143'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']) ?? _parseDate(json['created_at_232143']) ?? DateTime.now(),
    );
  }

  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['challenge_id_232143']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? map['name']?.toString() ?? '',
      type: map['type_232143']?.toString() ?? map['type']?.toString() ?? 'no_spend',
      target: (map['target_amount_232143'] as num?)?.toDouble() ?? (map['target'] as num?)?.toDouble() ?? 0.0,
      currentProgress:
          (map['current_amount_232143'] as num?)?.toDouble() ?? (map['current_progress'] as num?)?.toDouble() ?? 0.0,
      startDate: _parseDate(map['start_date_232143']) ?? _parseDate(map['start_date']) ?? DateTime.now(),
      endDate:
          _parseDate(map['end_date_232143']) ??
          _parseDate(map['end_date']) ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: _parseBool(map['is_active_232143']) ?? _parseBool(map['is_active']) ?? true,
      streak: (map['streak_days_232143'] as num?)?.toInt() ?? (map['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (map['best_streak_232143'] as num?)?.toInt() ?? (map['best_streak'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(map['created_at_232143']) ?? _parseDate(map['created_at']) ?? DateTime.now(),
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

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    return null;
  }

  static List<String> get types => ['no_spend', 'savings_target', 'budget_limit', 'custom'];
}
