import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/models/currency_model.dart';
import 'package:financial_app/services/exchange_rate_service.dart';
import 'package:financial_app/services/data/exchange_rate_data_service.dart';

void main() {
  group('CurrencyModel', () {
    test('should have correct IDR properties', () {
      expect(CurrencyModel.idr.code, 'IDR');
      expect(CurrencyModel.idr.symbol, 'Rp');
      expect(CurrencyModel.idr.decimalPlaces, 0);
    });

    test('should have correct USD properties', () {
      expect(CurrencyModel.usd.code, 'USD');
      expect(CurrencyModel.usd.symbol, r'$');
      expect(CurrencyModel.usd.decimalPlaces, 2);
    });

    test('should have correct EUR properties', () {
      expect(CurrencyModel.eur.code, 'EUR');
      expect(CurrencyModel.eur.symbol, '€');
    });

    test('should have correct JPY properties', () {
      expect(CurrencyModel.jpy.code, 'JPY');
      expect(CurrencyModel.jpy.decimalPlaces, 0);
    });

    test('should support at least 8 currencies', () {
      expect(CurrencyModel.supportedCurrencies.length, greaterThanOrEqualTo(8));
    });

    test('should find currency by code', () {
      final currency = CurrencyModel.fromCode('USD');
      expect(currency, isNotNull);
      expect(currency!.code, 'USD');
    });

    test('should return null for unsupported currency', () {
      final currency = CurrencyModel.fromCode('XYZ');
      expect(currency, isNull);
    });

    test('should serialize to JSON', () {
      final json = CurrencyModel.usd.toJson();
      expect(json['code'], 'USD');
      expect(json['name'], 'US Dollar');
      expect(json['symbol'], r'$');
    });

    test('should deserialize from JSON', () {
      final json = {
        'code': 'EUR',
        'name': 'Euro',
        'symbol': '€',
        'decimalPlaces': 2,
        'countryCode': 'EU',
      };
      final currency = CurrencyModel.fromJson(json);
      expect(currency.code, 'EUR');
      expect(currency.symbol, '€');
    });

    test('toString should return code and symbol', () {
      expect(CurrencyModel.idr.toString(), 'IDR (Rp)');
    });
  });

  group('ExchangeRateService', () {
    late ExchangeRateService service;

    setUp(() {
      service = ExchangeRateService(
        exchangeRateData: ExchangeRateDataService(),
      );
    });

    test('should convert same currency to same amount', () async {
      final result = await service.convert(
        amount: 100000.0,
        fromCurrency: 'IDR',
        toCurrency: 'IDR',
      );
      expect(result, 100000.0);
    });

    test('should get exchange rate for same currency as 1.0', () async {
      final rate = await service.getExchangeRate('USD', 'USD');
      expect(rate, 1.0);
    });

    test('should format IDR amount without decimals', () {
      final formatted = service.formatAmount(50000.0, 'IDR');
      expect(formatted, 'Rp 50000');
    });

    test('should format USD amount with decimals', () {
      final formatted = service.formatAmount(100.50, 'USD');
      expect(formatted, r'$ 100.50');
    });

    test('should format JPY amount without decimals', () {
      final formatted = service.formatAmount(10000.0, 'JPY');
      expect(formatted, '¥ 10000');
    });

    test('should calculate portfolio value correctly', () async {
      final balances = <String, double>{'IDR': 16000000.0, 'USD': 100.0};

      final total = await service.calculatePortfolioValue(balances);

      // 16000000 IDR + (100 USD * ~16000 IDR/USD) = ~17600000 IDR
      expect(total, greaterThan(16000000.0));
    });

    test('should return empty distribution for zero balances', () async {
      final distribution = await service.getCurrencyDistribution(
        <String, double>{},
      );
      expect(distribution, isEmpty);
    });

    test('should calculate currency distribution', () async {
      final balances = <String, double>{'IDR': 16000000.0, 'USD': 100.0};

      final distribution = await service.getCurrencyDistribution(balances);
      expect(distribution.isNotEmpty, true);

      // Check that percentages add up to 100
      final totalPercentage = distribution.fold<double>(
        0,
        (sum, d) => sum + (d['percentage'] as double),
      );
      expect(totalPercentage, closeTo(100.0, 0.01));
    });

    test('should get default base currency as IDR', () async {
      final baseCurrency = await service.getBaseCurrency();
      expect(baseCurrency, 'IDR');
    });

    test('should get rates map', () async {
      final rates = await service.getRates();
      expect(rates.containsKey('IDR'), true);
      expect(rates.containsKey('USD'), true);
      expect(rates['IDR'], 1.0);
    });

    test('should reset to default rates', () async {
      await service.resetToDefaults();
      final rates = await service.getRates();
      expect(rates['USD'], 16000.0);
    });
  });
}
