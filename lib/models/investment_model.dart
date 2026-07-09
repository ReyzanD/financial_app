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
  double get profitLossPercentage =>
      totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;

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
      id:
          json['id']?.toString() ??
          json['investment_id_232143']?.toString() ??
          '',
      name: json['name']?.toString() ?? json['name_232143']?.toString() ?? '',
      type:
          json['type']?.toString() ??
          json['type_232143']?.toString() ??
          'other',
      quantity:
          (json['quantity'] as num?)?.toDouble() ??
          (json['quantity_232143'] as num?)?.toDouble() ??
          0.0,
      buyPrice:
          (json['buy_price'] as num?)?.toDouble() ??
          (json['buy_price_232143'] as num?)?.toDouble() ??
          0.0,
      currentPrice:
          (json['current_price'] as num?)?.toDouble() ??
          (json['current_price_232143'] as num?)?.toDouble() ??
          0.0,
      buyDate:
          _parseDate(json['buy_date']) ??
          _parseDate(json['buy_date_232143']) ??
          DateTime.now(),
      ticker: json['ticker']?.toString() ?? json['ticker_232143']?.toString(),
      createdAt:
          _parseDate(json['created_at']) ??
          _parseDate(json['created_at_232143']) ??
          DateTime.now(),
    );
  }

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id:
          map['investment_id_232143']?.toString() ??
          map['id']?.toString() ??
          '',
      name: map['name_232143']?.toString() ?? map['name']?.toString() ?? '',
      type:
          map['type_232143']?.toString() ?? map['type']?.toString() ?? 'other',
      quantity:
          (map['quantity_232143'] as num?)?.toDouble() ??
          (map['quantity'] as num?)?.toDouble() ??
          0.0,
      buyPrice:
          (map['buy_price_232143'] as num?)?.toDouble() ??
          (map['buy_price'] as num?)?.toDouble() ??
          0.0,
      currentPrice:
          (map['current_price_232143'] as num?)?.toDouble() ??
          (map['current_price'] as num?)?.toDouble() ??
          0.0,
      buyDate:
          _parseDate(map['buy_date_232143']) ??
          _parseDate(map['buy_date']) ??
          DateTime.now(),
      ticker: map['ticker_232143']?.toString() ?? map['ticker']?.toString(),
      createdAt:
          _parseDate(map['created_at_232143']) ??
          _parseDate(map['created_at']) ??
          DateTime.now(),
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

  static List<String> get types => [
    'stock',
    'mutual_fund',
    'crypto',
    'bond',
    'gold',
    'deposit',
    'other',
  ];
}
