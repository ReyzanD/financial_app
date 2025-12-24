/// Transaction Entity (Domain Layer)
class TransactionEntity {
  final String id;
  final String type; // 'income', 'expense', 'transfer'
  final double amount;
  final String categoryId;
  final String categoryName;
  final String description;
  final DateTime transactionDate;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.transactionDate,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  factory TransactionEntity.fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? 'Uncategorized',
      description: json['description']?.toString() ?? '',
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'].toString())
          : DateTime.now(),
      locationName: json['location_name']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'description': description,
      'date': transactionDate.toIso8601String(),
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

