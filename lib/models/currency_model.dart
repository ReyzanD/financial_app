/// Currency model for multi-currency support
class CurrencyModel {
  final String code;
  final String name;
  final String symbol;
  final int decimalPlaces;
  final String countryCode;

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.symbol,
    this.decimalPlaces = 2,
    this.countryCode = '',
  });

  /// Common currencies
  static const CurrencyModel idr = CurrencyModel(
    code: 'IDR',
    name: 'Indonesian Rupiah',
    symbol: 'Rp',
    decimalPlaces: 0,
    countryCode: 'ID',
  );

  static const CurrencyModel usd = CurrencyModel(
    code: 'USD',
    name: 'US Dollar',
    symbol: r'$',
    decimalPlaces: 2,
    countryCode: 'US',
  );

  static const CurrencyModel eur = CurrencyModel(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    decimalPlaces: 2,
    countryCode: 'EU',
  );

  static const CurrencyModel gbp = CurrencyModel(
    code: 'GBP',
    name: 'British Pound',
    symbol: '£',
    decimalPlaces: 2,
    countryCode: 'GB',
  );

  static const CurrencyModel jpy = CurrencyModel(
    code: 'JPY',
    name: 'Japanese Yen',
    symbol: '¥',
    decimalPlaces: 0,
    countryCode: 'JP',
  );

  static const CurrencyModel sgd = CurrencyModel(
    code: 'SGD',
    name: 'Singapore Dollar',
    symbol: r'S$',
    decimalPlaces: 2,
    countryCode: 'SG',
  );

  static const CurrencyModel myr = CurrencyModel(
    code: 'MYR',
    name: 'Malaysian Ringgit',
    symbol: 'RM',
    decimalPlaces: 2,
    countryCode: 'MY',
  );

  static const CurrencyModel aud = CurrencyModel(
    code: 'AUD',
    name: 'Australian Dollar',
    symbol: r'A$',
    decimalPlaces: 2,
    countryCode: 'AU',
  );

  /// Get all supported currencies
  static List<CurrencyModel> get supportedCurrencies => [idr, usd, eur, gbp, jpy, sgd, myr, aud];

  /// Find currency by code
  static CurrencyModel? fromCode(String code) {
    for (var currency in supportedCurrencies) {
      if (currency.code == code.toUpperCase()) {
        return currency;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name, 'symbol': symbol, 'decimalPlaces': decimalPlaces, 'countryCode': countryCode};
  }

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      code: json['code'] as String? ?? 'IDR',
      name: json['name'] as String? ?? 'Indonesian Rupiah',
      symbol: json['symbol'] as String? ?? 'Rp',
      decimalPlaces: json['decimalPlaces'] as int? ?? 2,
      countryCode: json['countryCode'] as String? ?? '',
    );
  }

  @override
  String toString() => '$code ($symbol)';
}
