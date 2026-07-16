class TransactionTagModel {
  final String id;
  final String name;
  final String color;
  final String? icon;
  final int usageCount;
  final DateTime createdAt;

  TransactionTagModel({
    required this.id,
    required this.name,
    this.color = '#8B5FBF',
    this.icon,
    this.usageCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'color': color};
  }

  factory TransactionTagModel.fromJson(Map<String, dynamic> json) {
    return TransactionTagModel(
      id: json['id']?.toString() ?? json['tag_id_232143']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      color: json['color']?.toString() ?? json['color_232143']?.toString() ?? '#8B5FBF',
      icon: json['icon']?.toString() ?? json['icon_232143']?.toString(),
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(json['created_at']) ?? _parseDate(json['created_at_232143']) ?? DateTime.now(),
    );
  }

  factory TransactionTagModel.fromMap(Map<String, dynamic> map) {
    return TransactionTagModel(
      id: map['tag_id_232143']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? map['name']?.toString() ?? '',
      color: map['color_232143']?.toString() ?? map['color']?.toString() ?? '#8B5FBF',
      icon: map['icon_232143']?.toString() ?? map['icon']?.toString(),
      usageCount: (map['usage_count_232143'] as num?)?.toInt() ?? (map['usage_count'] as num?)?.toInt() ?? 0,
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
