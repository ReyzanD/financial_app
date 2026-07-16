enum BillType { electricity, water, internet, phone, rent, insurance, subscription, other }

class Bill {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final BillType type;
  final bool isPaid;

  Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.type,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'type': type.name,
      'is_paid': isPaid,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name_232143': name,
      'amount_232143': amount,
      'due_date_232143': dueDate.toIso8601String().split('T')[0],
      'type_232143': type.name,
      'is_paid_232143': isPaid ? 1 : 0,
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id']?.toString() ?? json['obligation_id_232143']?.toString() ?? '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? (json['amount_232143'] as num?)?.toDouble() ?? 0.0,
      dueDate:
          _parseDate(json['due_date']) ??
          _parseDate(json['due_date_232143']) ??
          DateTime.now().add(const Duration(days: 30)),
      type: BillType.values.firstWhere(
        (e) => e.name == json['type']?.toString() || e.name == json['type_232143']?.toString(),
        orElse: () => BillType.other,
      ),
      isPaid:
          json['is_paid'] == true ||
          json['is_paid'] == 1 ||
          json['is_paid_232143'] == 1 ||
          json['is_paid_232143'] == true,
    );
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['obligation_id_232143']?.toString() ?? '',
      name: map['name_232143']?.toString() ?? '',
      amount: (map['amount_232143'] as num?)?.toDouble() ?? 0.0,
      dueDate: _parseDate(map['due_date_232143']) ?? DateTime.now(),
      type: BillType.values.firstWhere((e) => e.name == map['type_232143']?.toString(), orElse: () => BillType.other),
      isPaid: map['is_paid_232143'] == 1 || map['is_paid_232143'] == true,
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
