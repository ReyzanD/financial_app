import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money2/money2.dart';
import 'package:financial_app/services/financial_calculator.dart';
import 'package:financial_app/services/ai_service.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/encryption_service.dart';
import 'package:financial_app/models/financial_overview.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/transaction_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Unified facade for all financial operations
/// Provides a single entry point for financial calculations, AI recommendations, and forecasts
/// Includes caching for performance (24h TTL)
class FinancialFacade {
  final FinancialCalculator _calculator = FinancialCalculator();
  final AIService _aiService = AIService();
  final ApiService _apiService = ApiService();
  final EncryptionService _encryptionService = EncryptionService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _cacheKey = 'financial_overview_cache';
  static const Duration _cacheTTL = Duration(hours: 24);

  /// Get comprehensive financial overview
  /// Orchestrates all services and combines results
  Future<FinancialOverview> getOverview({
    required List<TransactionModel> transactions,
    double? inflationRate,
    double? taxRate,
    bool useCache = true,
  }) async {
    try {
      // Check cache first
      if (useCache) {
        final cached = await _getCachedOverview();
        if (cached != null) {
          LoggerService.debug('[FinancialFacade] Returning cached overview');
          return cached;
        }
      }

      // Get default rates if not provided
      final effectiveInflationRate = inflationRate ?? 
          (await _getInflationRate()) ?? 
          _calculator.getIndonesiaDefaultRates()['inflationRate']!;
      final effectiveTaxRate = taxRate ?? 
          (await _getTaxRate()) ?? 
          _calculator.getIndonesiaDefaultRates()['taxRate']!;

      // Calculate income and expenses
      double totalIncome = 0;
      double totalExpenses = 0;
      final expenseList = <Map<String, dynamic>>[];
      final incomeList = <Map<String, dynamic>>[];

      for (var transaction in transactions) {
        if (transaction.type.toLowerCase() == 'income') {
          totalIncome += transaction.amount;
          incomeList.add({
            'amount': transaction.amount,
            'category': transaction.categoryName,
          });
        } else {
          totalExpenses += transaction.amount;
          expenseList.add({
            'amount': transaction.amount,
            'category': transaction.categoryName,
          });
        }
      }

      // Calculate balance
      final balanceData = _calculator.calculateBalance(
        income: totalIncome,
        expenses: totalExpenses,
      );
      final balanceMoney = balanceData['balance'] as Money;

      // Calculate savings rate
      final savingsRate = _calculator.calculateSavingsRate(
        income: totalIncome,
        expenses: totalExpenses,
      );

      // Calculate financial health score
      final healthScoreData = _calculator.calculateFinancialHealthScore(
        income: totalIncome,
        expenses: totalExpenses,
        savings: balanceMoney.minorUnits.toDouble(),
        inflationRate: effectiveInflationRate,
        taxRate: effectiveTaxRate,
      );
      final healthScore = healthScoreData['score'] as double;
      final healthLevel = healthScoreData['level'] as String;
      final afterTaxIncome = healthScoreData['afterTaxIncome'] as Money?;
      final realSavings = healthScoreData['realSavings'] as Money?;

      // Calculate breakdowns
      final expenseBreakdown = _calculator.calculateExpenseBreakdown(
        expenses: expenseList,
      );
      final incomeBreakdown = _calculator.calculateIncomeBreakdown(
        incomes: incomeList,
      );

      // Get AI recommendations
      List<Map<String, dynamic>>? recommendations;
      try {
        final aiRecs = await _aiService.generateRecommendations();
        recommendations = [aiRecs];
      } catch (e) {
        LoggerService.warning('Error getting AI recommendations', error: e);
      }

      // Get expense forecast
      Map<String, dynamic>? forecast;
      try {
        forecast = await _aiService.getExpenseForecast();
      } catch (e) {
        LoggerService.warning('Error getting expense forecast', error: e);
      }

      // Get budget status
      Map<String, dynamic>? budgetStatus;
      try {
        final budgets = await _apiService.getBudgets();
        if (budgets.isNotEmpty) {
          budgetStatus = {
            'totalBudgets': budgets.length,
            'overBudget': budgets.where((b) {
              final spent = (b['spent'] ?? 0).toDouble();
              final limit = (b['limit'] ?? 1).toDouble();
              return spent > limit;
            }).length,
          };
        }
      } catch (e) {
        LoggerService.warning('Error getting budget status', error: e);
      }

      // Create overview
      final overview = FinancialOverview(
        balance: balanceMoney,
        savingsRate: savingsRate,
        healthScore: healthScore,
        healthLevel: healthLevel,
        expenseBreakdown: expenseBreakdown,
        incomeBreakdown: incomeBreakdown,
        forecast: forecast,
        recommendations: recommendations,
        budgetStatus: budgetStatus,
        afterTaxIncome: afterTaxIncome,
        realSavings: realSavings,
      );

      // Cache the result
      if (useCache) {
        await _cacheOverview(overview);
      }

      return overview;
    } catch (e) {
      LoggerService.error('Error getting financial overview', error: e);
      rethrow;
    }
  }

  /// Get cached overview if available and not expired (decrypts encrypted cache)
  Future<FinancialOverview?> _getCachedOverview() async {
    try {
      // Check timestamp first
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString('${_cacheKey}_timestamp');
      if (timestampStr == null) return null;
      
      final timestamp = DateTime.parse(timestampStr);
      final age = DateTime.now().difference(timestamp);
      if (age >= _cacheTTL) {
        // Cache expired, remove it
        await _secureStorage.delete(key: _cacheKey);
        await prefs.remove('${_cacheKey}_timestamp');
        return null;
      }
      
      // Get encrypted data from secure storage
      final encryptedData = await _secureStorage.read(key: _cacheKey);
      if (encryptedData == null) return null;
      
      // Decrypt
      final decryptedJson = await _encryptionService.decrypt(encryptedData);
      final cached = FinancialOverview.fromJson(jsonDecode(decryptedJson));
      
      return cached;
    } catch (e) {
      LoggerService.warning('Error reading cached overview', error: e);
      return null;
    }
  }

  /// Cache overview (encrypted for security)
  Future<void> _cacheOverview(FinancialOverview overview) async {
    try {
      // Encrypt sensitive financial data before caching
      final jsonData = jsonEncode(overview.toJson());
      final encrypted = await _encryptionService.encrypt(jsonData);
      
      // Store encrypted data in secure storage
      await _secureStorage.write(key: _cacheKey, value: encrypted);
      
      // Also store timestamp in regular prefs for TTL checking
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_cacheKey}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      LoggerService.warning('Error caching overview', error: e);
    }
  }

  /// Get user's inflation rate from settings
  Future<double?> _getInflationRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('inflation_rate');
    } catch (e) {
      return null;
    }
  }

  /// Get user's tax rate from settings
  Future<double?> _getTaxRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('tax_rate');
    } catch (e) {
      return null;
    }
  }

  /// Clear cache (both encrypted and timestamp)
  Future<void> clearCache() async {
    try {
      await _secureStorage.delete(key: _cacheKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKey}_timestamp');
    } catch (e) {
      LoggerService.warning('Error clearing cache', error: e);
    }
  }

  /// Store Money value securely (encrypted)
  Future<void> storeSecure(String key, Money value) async {
    try {
      final encrypted = await _encryptionService.encrypt(value.minorUnits.toString());
      await _secureStorage.write(key: key, value: encrypted);
    } catch (e) {
      LoggerService.warning('Error storing secure Money value', error: e);
    }
  }

  /// Get secure Money value (decrypted)
  Future<Money?> getSecure(String key) async {
    try {
      final encrypted = await _secureStorage.read(key: key);
      if (encrypted == null) return null;
      
      final decrypted = await _encryptionService.decrypt(encrypted);
      final amount = int.parse(decrypted);
      return Money.fromInt(amount, isoCode: 'IDR');
    } catch (e) {
      LoggerService.warning('Error getting secure Money value', error: e);
      return null;
    }
  }

  /// Parse natural language query
  Future<Map<String, dynamic>> parseQuery(String query) async {
    return await _aiService.parseNaturalLanguageQuery(query);
  }
}

