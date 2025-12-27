import 'dart:convert';

class TransactionModel {
  final String id;
  final double amount;
  final String type;
  final String description;
  final String categoryId;
  final String categoryName;
  final String categoryColor;
  final String paymentMethod;
  final DateTime transactionDate;
  final DateTime createdAt;
  final Map<String, dynamic>? locationData;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.paymentMethod,
    required this.transactionDate,
    required this.createdAt,
    this.locationData,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Map database field names to model fields
    final id = json['transaction_id_232143'] ?? json['id'] ?? '';
    final amountValue = json['amount_232143'] ?? json['amount'];
    final amount = amountValue != null ? (amountValue as num).toDouble() : 0.0;
    final type = json['type_232143'] ?? json['type'] ?? 'expense';
    final description = json['description_232143'] ?? json['description'] ?? '';
    final categoryId = json['category_id_232143'] ?? json['category_id'] ?? '';
    final categoryName =
        json['category_name'] ?? json['category'] ?? 'Uncategorized';
    final categoryColor =
        json['category_color'] ?? json['color_232143'] ?? '#808080';
    final paymentMethod =
        json['payment_method_232143'] ?? json['payment_method'] ?? 'cash';
    final dateStr =
        json['transaction_date_232143'] ??
        json['date'] ??
        json['transaction_date'];
    final createdAtStr =
        json['created_at_232143'] ?? json['created_at'] ?? dateStr;

    return TransactionModel(
      id: id,
      amount: amount,
      type: type,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      paymentMethod: paymentMethod,
      transactionDate:
          dateStr != null ? _parseDate(dateStr.toString()) : DateTime.now(),
      createdAt:
          createdAtStr != null
              ? _parseDate(createdAtStr.toString())
              : DateTime.now(),
      locationData: _parseLocationData(json),
    );
  }

  static Map<String, dynamic>? _parseLocationData(Map<String, dynamic> json) {
    try {
      if (json['location_data_232143'] != null) {
        if (json['location_data_232143'] is String) {
          final decoded = jsonDecode(json['location_data_232143'] as String);
          return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
        } else if (json['location_data_232143'] is Map) {
          return Map<String, dynamic>.from(json['location_data_232143'] as Map);
        }
      }
      if (json['location'] != null && json['location'].toString().isNotEmpty) {
        return {'address': json['location'].toString()};
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
  }

  static DateTime _parseDate(String dateString) {
    if (dateString.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try parsing date in format "Mon, 03 Nov 2025 00:00:00 GMT"
      final dateFormat = RegExp(
        r'^[A-Za-z]+, (\d{2}) ([A-Za-z]+) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
      );
      final match = dateFormat.firstMatch(dateString);

      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = _parseMonth(match.group(2)!);
        final year = int.parse(match.group(3)!);
        final hour = int.parse(match.group(4)!);
        final minute = int.parse(match.group(5)!);
        final second = int.parse(match.group(6)!);

        return DateTime.utc(year, month, day, hour, minute, second);
      }

      throw FormatException('Invalid date format: $dateString');
    }
  }

  static int _parseMonth(String month) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    return months[month] ?? DateTime.january;
  }
}
