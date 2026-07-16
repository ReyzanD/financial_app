class SubscriptionModel {
  final String id;
  final String name;
  final double cost;
  final String cycle;
  final String category;
  final DateTime startDate;
  final DateTime? nextRenewal;
  final bool isActive;
  final String? notes;
  final String? accountId;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.cost,
    required this.cycle,
    this.category = 'subscription',
    required this.startDate,
    this.nextRenewal,
    this.isActive = true,
    this.notes,
    this.accountId,
    required this.createdAt,
  });

  double get monthlyCost {
    switch (cycle) {
      case 'weekly':
        return cost * 4.33;
      case 'yearly':
        return cost / 12;
      default:
        return cost;
    }
  }

  double get yearlyCost {
    return monthlyCost * 12;
  }

  int get daysUntilRenewal {
    if (nextRenewal == null) return -1;
    return nextRenewal!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'subscription_id_232143': id,
      'name': name,
      'cost': cost,
      'cycle': cycle,
      'category': category,
      'start_date': startDate.toIso8601String().split('T')[0],
      'next_renewal': nextRenewal?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'notes': notes,
      'account_id': accountId,
      'created_at': createdAt.toIso8601String().split('T')[0],
    };
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id']?.toString() ?? json['subscription_id_232143']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? (json['cost_232143'] as num?)?.toDouble() ?? 0.0,
      cycle: json['cycle']?.toString() ?? json['cycle_232143']?.toString() ?? 'monthly',
      category: json['category']?.toString() ?? json['category_232143']?.toString() ?? 'subscription',
      startDate: _parseDate(json['start_date']) ?? _parseDate(json['start_date_232143']) ?? DateTime.now(),
      nextRenewal: _parseDate(json['next_renewal']) ?? _parseDate(json['next_renewal_232143']),
      isActive: _parseBool(json['is_active']) ?? _parseBool(json['is_active_232143']) ?? true,
      notes: json['notes']?.toString() ?? json['notes_232143']?.toString(),
      accountId: json['account_id']?.toString() ?? json['account_id_232143']?.toString(),
      createdAt: _parseDate(json['created_at']) ?? _parseDate(json['created_at_232143']) ?? DateTime.now(),
    );
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      id: map['subscription_id_232143']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? map['name']?.toString() ?? '',
      cost: (map['cost_232143'] as num?)?.toDouble() ?? (map['cost'] as num?)?.toDouble() ?? 0.0,
      cycle: map['cycle_232143']?.toString() ?? map['cycle']?.toString() ?? 'monthly',
      category: map['category_232143']?.toString() ?? map['category']?.toString() ?? 'subscription',
      startDate: _parseDate(map['start_date_232143']) ?? _parseDate(map['start_date']) ?? DateTime.now(),
      nextRenewal: _parseDate(map['next_renewal_232143']) ?? _parseDate(map['next_renewal']),
      isActive: _parseBool(map['is_active_232143']) ?? _parseBool(map['is_active']) ?? true,
      notes: map['notes_232143']?.toString() ?? map['notes']?.toString(),
      accountId: map['account_id_232143']?.toString() ?? map['account_id']?.toString(),
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

  static List<String> get cycles => ['weekly', 'monthly', 'yearly'];
}
