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
    return TransactionModel(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      type: json['type'],
      description: json['description'],
      categoryId: json['category_id'] ?? '',
      categoryName: json['category'] ?? 'Uncategorized',
      categoryColor: json['category_color'] ?? '#808080',
      paymentMethod: json['payment_method'] ?? 'cash',
      transactionDate: _parseDate(json['date']),
      createdAt: _parseDate(json['created_at'] ?? json['date']),
      locationData:
          json['location'] != null && json['location'] != ''
              ? {'address': json['location']}
              : null,
    );
  }

  static DateTime _parseDate(String dateString) {
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
