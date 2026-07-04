class AccountModel {
  final String id;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final double balance;
  final String currency;
  final String? accountNumber;
  final String? bankName;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.balance,
    this.currency = 'IDR',
    this.accountNumber,
    this.bankName,
    this.isActive = true,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'balance': balance,
      'currency': currency,
      'account_number': accountNumber,
      'bank_name': bankName,
      'is_active': isActive ? 1 : 0,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'account_id_232143': id,
      'name_232143': name,
      'type_232143': type,
      'icon_232143': icon,
      'color_232143': color,
      'balance_232143': balance,
      'currency_232143': currency,
      'account_number_232143': accountNumber,
      'bank_name_232143': bankName,
      'is_active_232143': isActive ? 1 : 0,
      'is_default_232143': isDefault ? 1 : 0,
      'created_at_232143': createdAt.toIso8601String(),
      'updated_at_232143': updatedAt?.toIso8601String(),
    };
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id']?.toString() ?? json['account_id_232143']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      type: json['type']?.toString() ?? json['type_232143']?.toString() ?? 'cash',
      icon: json['icon']?.toString() ?? json['icon_232143']?.toString(),
      color: json['color']?.toString() ?? json['color_232143']?.toString(),
      balance: (json['balance'] as num?)?.toDouble() ?? (json['balance_232143'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? json['currency_232143']?.toString() ?? 'IDR',
      accountNumber: json['account_number']?.toString() ?? json['account_number_232143']?.toString(),
      bankName: json['bank_name']?.toString() ?? json['bank_name_232143']?.toString(),
      isActive: _parseBool(json['is_active']) ?? _parseBool(json['is_active_232143']) ?? true,
      isDefault: _parseBool(json['is_default']) ?? _parseBool(json['is_default_232143']) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : json['created_at_232143'] != null
              ? DateTime.parse(json['created_at_232143'].toString())
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : json['updated_at_232143'] != null
              ? DateTime.parse(json['updated_at_232143'].toString())
              : null,
    );
  }

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['account_id_232143']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? map['name']?.toString() ?? '',
      type: map['type_232143']?.toString() ?? map['type']?.toString() ?? 'cash',
      icon: map['icon_232143']?.toString() ?? map['icon']?.toString(),
      color: map['color_232143']?.toString() ?? map['color']?.toString(),
      balance: (map['balance_232143'] as num?)?.toDouble() ?? (map['balance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency_232143']?.toString() ?? map['currency']?.toString() ?? 'IDR',
      accountNumber: map['account_number_232143']?.toString() ?? map['account_number']?.toString(),
      bankName: map['bank_name_232143']?.toString() ?? map['bank_name']?.toString(),
      isActive: _parseBool(map['is_active_232143']) ?? _parseBool(map['is_active']) ?? true,
      isDefault: _parseBool(map['is_default_232143']) ?? _parseBool(map['is_default']) ?? false,
      createdAt: map['created_at_232143'] != null
          ? DateTime.parse(map['created_at_232143'].toString())
          : map['created_at'] != null
              ? DateTime.parse(map['created_at'].toString())
              : DateTime.now(),
      updatedAt: map['updated_at_232143'] != null
          ? DateTime.parse(map['updated_at_232143'].toString())
          : map['updated_at'] != null
              ? DateTime.parse(map['updated_at'].toString())
              : null,
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is num) return value.toInt() == 1;
    return null;
  }

  AccountModel copyWith({
    String? name,
    String? type,
    String? icon,
    String? color,
    double? balance,
    String? currency,
    String? accountNumber,
    String? bankName,
    bool? isActive,
    bool? isDefault,
  }) {
    return AccountModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static List<String> get types => ['cash', 'bank', 'e_wallet'];

  static List<Map<String, dynamic>> get defaultAccounts => [
        {'name': 'Cash', 'type': 'cash', 'icon': 'wallet', 'color': '#4CAF50'},
        {'name': 'Bank Account', 'type': 'bank', 'icon': 'account_balance', 'color': '#2196F3'},
        {'name': 'E-Wallet', 'type': 'e_wallet', 'icon': 'phone_android', 'color': '#FF9800'},
      ];
}
