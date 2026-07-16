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
