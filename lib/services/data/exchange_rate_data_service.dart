import 'package:sqflite/sqflite.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Exchange Rate CRUD operations.
class ExchangeRateDataService {
  final LocalDatabaseService _dbService;

  ExchangeRateDataService({LocalDatabaseService? dbService})
    : _dbService = dbService ?? LocalDatabaseService();

  Future<Map<String, double>> getExchangeRates() async {
    try {
      final db = await _dbService.database;
      final rates = await db.query(
        'exchange_rates_232143',
        where: 'from_currency_232143 = ?',
        whereArgs: ['IDR'],
      );

      final rateMap = <String, double>{};
      for (var rate in rates) {
        final toCurrency = rate['to_currency_232143'] as String;
        final rateValue = (rate['rate_232143'] as num?)?.toDouble() ?? 1.0;
        rateMap[toCurrency] = rateValue;
      }

      if (rateMap.isEmpty) {
        rateMap['IDR'] = 1.0;
        rateMap['USD'] = 16000.0;
        rateMap['EUR'] = 17500.0;
        rateMap['GBP'] = 20300.0;
        rateMap['JPY'] = 106.0;
        rateMap['SGD'] = 11900.0;
        rateMap['MYR'] = 3500.0;
        rateMap['AUD'] = 10500.0;
      }

      return rateMap;
    } catch (e) {
      LoggerService.error('Error getting exchange rates', error: e);
      return {
        'IDR': 1.0,
        'USD': 16000.0,
        'EUR': 17500.0,
        'GBP': 20300.0,
        'JPY': 106.0,
        'SGD': 11900.0,
        'MYR': 3500.0,
        'AUD': 10500.0,
      };
    }
  }

  Future<void> updateExchangeRates(Map<String, double> rates) async {
    try {
      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      for (var entry in rates.entries) {
        final rateId = 'IDR_${entry.key}';
        await db.insert('exchange_rates_232143', {
          'rate_id_232143': rateId,
          'from_currency_232143': 'IDR',
          'to_currency_232143': entry.key,
          'rate_232143': entry.value,
          'last_updated_232143': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      LoggerService.info('✅ Exchange rates updated');
    } catch (e) {
      LoggerService.error('Error updating exchange rates', error: e);
      rethrow;
    }
  }
}
