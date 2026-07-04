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
    return {
      'name': name,
      'color': color,
    };
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
      icon: map['icon_232143']?.toString(),
      usageCount: 0,
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

class SplitModel {
  final String id;
  final String transactionId;
  final String participantName;
  final String participantPhone;
  final double amount;
  final double paidAmount;
  final bool isSettled;
  final String? notes;
  final DateTime createdAt;
  final DateTime? settledAt;

  SplitModel({
    required this.id,
    required this.transactionId,
    required this.participantName,
    this.participantPhone = '',
    required this.amount,
    this.paidAmount = 0,
    this.isSettled = false,
    this.notes,
    required this.createdAt,
    this.settledAt,
  });

  double get remainingAmount => amount - paidAmount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'participant_name': participantName,
      'participant_phone': participantPhone,
      'amount': amount,
      'paid_amount': paidAmount,
      'is_settled': isSettled ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'settled_at': settledAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'transaction_id': transactionId,
      'participant_name': participantName,
      'participant_phone': participantPhone,
      'amount': amount,
      'paid_amount': paidAmount,
      'is_settled': isSettled ? 1 : 0,
      'notes': notes,
    };
  }

  factory SplitModel.fromJson(Map<String, dynamic> json) {
    return SplitModel(
      id: json['id']?.toString() ?? json['split_id_232143']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? json['transaction_id_232143']?.toString() ?? '',
      participantName: json['participant_name']?.toString() ?? json['participant_name_232143']?.toString() ?? '',
      participantPhone: json['participant_phone']?.toString() ?? json['participant_phone_232143']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? (json['amount_232143'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? (json['paid_amount_232143'] as num?)?.toDouble() ?? 0.0,
      isSettled: _parseBool(json['is_settled']) ?? _parseBool(json['is_settled_232143']) ?? false,
      notes: json['notes']?.toString() ?? json['notes_232143']?.toString(),
      createdAt: _parseDate(json['created_at']) ?? _parseDate(json['created_at_232143']) ?? DateTime.now(),
      settledAt: _parseDate(json['settled_at']) ?? _parseDate(json['settled_at_232143']),
    );
  }

  factory SplitModel.fromMap(Map<String, dynamic> map) {
    return SplitModel(
      id: map['split_id_232143']?.toString() ?? map['id']?.toString() ?? '',
      transactionId: map['transaction_id_232143']?.toString() ?? map['transaction_id']?.toString() ?? '',
      participantName: map['participant_name_232143']?.toString() ?? map['participant_name']?.toString() ?? '',
      participantPhone: map['participant_phone_232143']?.toString() ?? map['participant_phone']?.toString() ?? '',
      amount: (map['amount_232143'] as num?)?.toDouble() ?? (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount_232143'] as num?)?.toDouble() ?? (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      isSettled: _parseBool(map['is_settled_232143']) ?? _parseBool(map['is_settled']) ?? false,
      notes: map['notes_232143']?.toString() ?? map['notes']?.toString(),
      createdAt: _parseDate(map['created_at_232143']) ?? _parseDate(map['created_at']) ?? DateTime.now(),
      settledAt: _parseDate(map['settled_at_232143']) ?? _parseDate(map['settled_at']),
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
}

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
      currentProgress: (json['current_progress'] as num?)?.toDouble() ?? (json['current_amount_232143'] as num?)?.toDouble() ?? 0.0,
      startDate: _parseDate(json['start_date']) ?? _parseDate(json['start_date_232143']) ?? DateTime.now(),
      endDate: _parseDate(json['end_date']) ?? _parseDate(json['end_date_232143']) ?? DateTime.now().add(const Duration(days: 30)),
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
      currentProgress: (map['current_amount_232143'] as num?)?.toDouble() ?? (map['current_progress'] as num?)?.toDouble() ?? 0.0,
      startDate: _parseDate(map['start_date_232143']) ?? _parseDate(map['start_date']) ?? DateTime.now(),
      endDate: _parseDate(map['end_date_232143']) ?? _parseDate(map['end_date']) ?? DateTime.now().add(const Duration(days: 30)),
      isActive: _parseBool(map['is_active_232143']) ?? _parseBool(map['is_active']) ?? true,
      streak: (map['streak_days_232143'] as num?)?.toInt() ?? (map['streak'] as num?)?.toInt() ?? 0,
      bestStreak: 0,
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

class InvestmentModel {
  final String id;
  final String name;
  final String type;
  final double quantity;
  final double buyPrice;
  final double currentPrice;
  final DateTime buyDate;
  final String? ticker;
  final DateTime createdAt;

  InvestmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    required this.buyDate,
    this.ticker,
    required this.createdAt,
  });

  double get totalValue => quantity * currentPrice;
  double get totalCost => quantity * buyPrice;
  double get profitLoss => totalValue - totalCost;
  double get profitLossPercentage => totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'quantity': quantity,
      'buy_price': buyPrice,
      'current_price': currentPrice,
      'buy_date': buyDate.toIso8601String(),
      'ticker': ticker,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'quantity': quantity,
      'buy_price': buyPrice,
      'current_price': currentPrice,
      'buy_date': buyDate.toIso8601String().split('T')[0],
      'ticker': ticker,
    };
  }

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id']?.toString() ?? json['investment_id_232143']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      type: json['type']?.toString() ?? json['type_232143']?.toString() ?? 'other',
      quantity: (json['quantity'] as num?)?.toDouble() ?? (json['quantity_232143'] as num?)?.toDouble() ?? 0.0,
      buyPrice: (json['buy_price'] as num?)?.toDouble() ?? (json['buy_price_232143'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? (json['current_price_232143'] as num?)?.toDouble() ?? 0.0,
      buyDate: _parseDate(json['buy_date']) ?? _parseDate(json['buy_date_232143']) ?? DateTime.now(),
      ticker: json['ticker']?.toString() ?? json['ticker_232143']?.toString(),
      createdAt: _parseDate(json['created_at']) ?? _parseDate(json['created_at_232143']) ?? DateTime.now(),
    );
  }

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['investment_id_232143']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? map['name']?.toString() ?? '',
      type: map['type_232143']?.toString() ?? map['type']?.toString() ?? 'other',
      quantity: (map['quantity_232143'] as num?)?.toDouble() ?? (map['quantity'] as num?)?.toDouble() ?? 0.0,
      buyPrice: (map['buy_price_232143'] as num?)?.toDouble() ?? (map['buy_price'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (map['current_price_232143'] as num?)?.toDouble() ?? (map['current_price'] as num?)?.toDouble() ?? 0.0,
      buyDate: _parseDate(map['buy_date_232143']) ?? _parseDate(map['buy_date']) ?? DateTime.now(),
      ticker: map['ticker_232143']?.toString() ?? map['ticker']?.toString(),
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

  static List<String> get types => ['stock', 'mutual_fund', 'crypto', 'bond', 'gold', 'deposit', 'other'];
}

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
      categoryName: json['category_name']?.toString(),
      description: json['description']?.toString() ?? json['description_232143']?.toString(),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
      lastUsed: _parseDate(json['last_used']) ?? DateTime.now(),
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
      categoryName: null,
      description: map['description_232143']?.toString() ?? map['description']?.toString(),
      icon: null,
      color: null,
      usageCount: 0,
      lastUsed: DateTime.now(),
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
