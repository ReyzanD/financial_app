import 'package:financial_app/services/local_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/currency_model.dart';
import 'package:financial_app/core/di/service_locator.dart';

class ExchangeRateService {
  final LocalDataService _localData = getIt<LocalDataService>();

  static const Map<String, double> _defaultRates = {
    'IDR': 1.0,
    'USD': 16000.0,
    'EUR': 17500.0,
    'GBP': 20300.0,
    'JPY': 106.0,
    'SGD': 11900.0,
    'MYR': 3500.0,
    'AUD': 10500.0,
  };

  Future<String> getBaseCurrency() async {
    return 'IDR';
  }

  Future<void> setBaseCurrency(String currencyCode) async {
    LoggerService.info('Base currency set to $currencyCode');
  }

  Future<double> getExchangeRate(String fromCode, String toCode) async {
    try {
      if (fromCode == toCode) return 1.0;

      final rates = await _localData.getExchangeRates();

      final fromRateInIDR =
          rates[fromCode.toUpperCase()] ??
          _defaultRates[fromCode.toUpperCase()] ??
          1.0;
      final toRateInIDR =
          rates[toCode.toUpperCase()] ??
          _defaultRates[toCode.toUpperCase()] ??
          1.0;

      return toRateInIDR / fromRateInIDR;
    } catch (e) {
      LoggerService.error('Error getting exchange rate', error: e);
      return 1.0;
    }
  }

  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) return amount;

    final rate = await getExchangeRate(fromCurrency, toCurrency);
    return amount * rate;
  }

  String formatAmount(double amount, String currencyCode) {
    final currency = CurrencyModel.fromCode(currencyCode.toUpperCase());
    if (currency == null) {
      return '$currencyCode ${amount.toStringAsFixed(2)}';
    }

    if (currency.decimalPlaces == 0) {
      return '${currency.symbol} ${amount.toStringAsFixed(0)}';
    }

    return '${currency.symbol} ${amount.toStringAsFixed(currency.decimalPlaces)}';
  }

  Future<Map<String, double>> getRates() async {
    return await _localData.getExchangeRates();
  }

  Future<void> updateRates(Map<String, double> rates) async {
    try {
      await _localData.updateExchangeRates(rates);
      LoggerService.info('Exchange rates updated');
    } catch (e) {
      LoggerService.error('Error updating rates', error: e);
    }
  }

  Future<DateTime?> getLastUpdated() async {
    return DateTime.now();
  }

  Future<void> resetToDefaults() async {
    try {
      await updateRates(Map.from(_defaultRates));
      LoggerService.info('Exchange rates reset to defaults');
    } catch (e) {
      LoggerService.error('Error resetting rates', error: e);
    }
  }

  Future<double> getRateChange(String currencyCode) async {
    return 0.0;
  }

  Future<double> calculatePortfolioValue(Map<String, double> balances) async {
    final baseCurrency = await getBaseCurrency();
    double totalInBase = 0;

    for (var entry in balances.entries) {
      final currencyCode = entry.key;
      final amount = entry.value;

      if (currencyCode == baseCurrency) {
        totalInBase += amount;
      } else {
        final converted = await convert(
          amount: amount,
          fromCurrency: currencyCode,
          toCurrency: baseCurrency,
        );
        totalInBase += converted;
      }
    }

    return totalInBase;
  }

  Future<List<Map<String, dynamic>>> getCurrencyDistribution(
    Map<String, double> balances,
  ) async {
    final totalValue = await calculatePortfolioValue(balances);
    if (totalValue == 0) return [];

    final distribution = <Map<String, dynamic>>[];

    for (var entry in balances.entries) {
      final currencyCode = entry.key;
      final amount = entry.value;
      final currency = CurrencyModel.fromCode(currencyCode);

      final valueInBase = await convert(
        amount: amount,
        fromCurrency: currencyCode,
        toCurrency: await getBaseCurrency(),
      );

      distribution.add({
        'currency':
            currency ??
            CurrencyModel(
              code: currencyCode,
              name: currencyCode,
              symbol: currencyCode,
            ),
        'amount': amount,
        'value_in_base': valueInBase,
        'percentage': (valueInBase / totalValue) * 100,
      });
    }

    distribution.sort((a, b) {
      return (b['value_in_base'] as double).compareTo(
        a['value_in_base'] as double,
      );
    });

    return distribution;
  }
}
