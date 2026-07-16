class TransactionTemplateModel {
  final String id;
  final String name;
  final double amount;
  final String type;
  final String? categoryId;
  final String? categoryName;
  final String? description;
  final String? icon;
  final String? color;
  final int usageCount;
  final DateTime lastUsed;
  final DateTime createdAt;

  TransactionTemplateModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.categoryId,
    this.categoryName,
    this.description,
    this.icon,
    this.color,
    this.usageCount = 0,
    required this.lastUsed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
      'icon': icon,
      'color': color,
      'usage_count': usageCount,
      'last_used': lastUsed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'description': description,
      'payment_method': null,
      'account_id': null,
      'is_recurring': false,
      'recurrence_pattern': null,
      'tags': null,
    };
  }

  factory TransactionTemplateModel.fromJson(Map<String, dynamic> json) {
    return TransactionTemplateModel(
      id: json['id']?.toString() ?? json['template_id_232143']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? (json['amount_232143'] as num?)?.toDouble() ?? 0.0,
      type: json['type']?.toString() ?? json['type_232143']?.toString() ?? 'expense',
      categoryId: json['category_id']?.toString() ?? json['category_id_232143']?.toString(),
      categoryName: json['category_name']?.toString() ?? json['category_name_232143']?.toString(),
      description: json['description']?.toString() ?? json['description_232143']?.toString(),
      icon: json['icon']?.toString() ?? json['icon_232143']?.toString(),
      color: json['color']?.toString() ?? json['color_232143']?.toString(),
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      lastUsed: _parseDate(json['last_used']) ?? _parseDate(json['last_used_232143']) ?? DateTime.now(),
      createdAt: _parseDate(json['created_at']) ?? _parseDate(json['created_at_232143']) ?? DateTime.now(),
    );
  }

  factory TransactionTemplateModel.fromMap(Map<String, dynamic> map) {
    return TransactionTemplateModel(
      id: map['template_id_232143']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? map['name']?.toString() ?? '',
      amount: (map['amount_232143'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type_232143']?.toString() ?? map['type']?.toString() ?? 'expense',
      categoryId: map['category_id_232143']?.toString() ?? map['category_id']?.toString(),
      categoryName: map['category_name_232143']?.toString() ?? map['category_name']?.toString(),
      description: map['description_232143']?.toString() ?? map['description']?.toString(),
      icon: map['icon_232143']?.toString() ?? map['icon']?.toString(),
      color: map['color_232143']?.toString() ?? map['color']?.toString(),
      usageCount: (map['usage_count_232143'] as num?)?.toInt() ?? (map['usage_count'] as num?)?.toInt() ?? 0,
      lastUsed: _parseDate(map['last_used_232143']) ?? _parseDate(map['last_used']) ?? DateTime.now(),
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
}
