import 'package:money2/money2.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service for statistical expense forecasting using moving average and trend analysis
/// Provides on-device ML capabilities without external dependencies
class ExpensePredictor {

  /// Predict expenses for the next N days based on historical data
  /// Returns forecast as Money object with confidence score
  Future<Map<String, dynamic>> predictNext30Days({
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      if (transactions.isEmpty) {
        return {
          'forecast': Money.fromInt(0, isoCode: 'IDR'),
          'forecastAmount': 0.0,
          'confidence': 0.0,
          'trend': 'insufficient_data',
          'message': 'Tidak ada data transaksi untuk prediksi',
        };
      }

      // Filter last 30 days of expenses
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final recentExpenses = transactions.where((t) {
        try {
          final date = DateTime.parse(t['date'] ?? '');
          final type = t['type']?.toString().toLowerCase() ?? 'expense';
          return date.isAfter(thirtyDaysAgo) && type == 'expense';
        } catch (e) {
          return false;
        }
      }).toList();

      if (recentExpenses.length < 3) {
        return {
          'forecast': Money.fromInt(0, isoCode: 'IDR'),
          'forecastAmount': 0.0,
          'confidence': 0.0,
          'trend': 'insufficient_data',
          'message': 'Data transaksi terlalu sedikit untuk prediksi akurat',
        };
      }

      // Extract daily amounts
      final dailyAmounts = _groupByDay(recentExpenses);
      final amounts = dailyAmounts.values.toList();

      // Calculate moving average (7-day window)
      final movingAverage = _calculateMovingAverage(amounts, windowSize: 7);
      
      // Detect trend
      final trend = _detectTrend(amounts);
      
      // Calculate forecast based on trend
      final baseForecast = movingAverage;
      Money forecastMoney;
      
      if (trend == 'increasing') {
        // Apply 5% growth
        forecastMoney = Money.fromInt(
          (baseForecast * 1.05).round(),
          isoCode: 'IDR',
        );
      } else if (trend == 'decreasing') {
        // Apply 5% reduction
        forecastMoney = Money.fromInt(
          (baseForecast * 0.95).round(),
          isoCode: 'IDR',
        );
      } else {
        // Stable trend
        forecastMoney = Money.fromInt(baseForecast.round(), isoCode: 'IDR');
      }

      // Calculate confidence based on data quality
      final confidence = _calculateConfidence(
        dataPoints: amounts.length,
        variance: _calculateVariance(amounts),
        trendStrength: _calculateTrendStrength(amounts),
      );

      LoggerService.debug(
        '[ExpensePredictor] Forecast: ${forecastMoney.toString()}, Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
      );

      return {
        'forecast': forecastMoney,
        'forecastAmount': forecastMoney.minorUnits.toDouble(),
        'confidence': confidence,
        'trend': trend,
        'message': _getTrendMessage(trend, confidence),
        'movingAverage': movingAverage,
      };
    } catch (e) {
      LoggerService.error('Error predicting expenses', error: e);
      return {
        'forecast': Money.fromInt(0, isoCode: 'IDR'),
        'forecastAmount': 0.0,
        'confidence': 0.0,
        'trend': 'error',
        'message': 'Terjadi kesalahan saat memprediksi pengeluaran',
      };
    }
  }

  /// Group expenses by day
  Map<DateTime, double> _groupByDay(List<Map<String, dynamic>> expenses) {
    final grouped = <DateTime, double>{};
    
    for (var expense in expenses) {
      try {
        final date = DateTime.parse(expense['date'] ?? '');
        final day = DateTime(date.year, date.month, date.day);
        final amount = (expense['amount'] ?? 0).toDouble();
        
        grouped[day] = (grouped[day] ?? 0.0) + amount;
      } catch (e) {
        continue;
      }
    }
    
    return grouped;
  }

  /// Calculate moving average with specified window size
  double _calculateMovingAverage(List<double> values, {int windowSize = 7}) {
    if (values.isEmpty) return 0.0;
    if (values.length < windowSize) {
      // Use all available data if less than window size
      return values.reduce((a, b) => a + b) / values.length;
    }
    
    // Calculate average of last N values
    final recentValues = values.sublist(values.length - windowSize);
    return recentValues.reduce((a, b) => a + b) / recentValues.length;
  }

  /// Detect trend: increasing, decreasing, or stable
  String _detectTrend(List<double> values) {
    if (values.length < 3) return 'stable';
    
    // Compare first half vs second half
    final midPoint = values.length ~/ 2;
    final firstHalf = values.sublist(0, midPoint);
    final secondHalf = values.sublist(midPoint);
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    final changePercent = ((secondAvg - firstAvg) / firstAvg) * 100;
    
    if (changePercent > 5) {
      return 'increasing';
    } else if (changePercent < -5) {
      return 'decreasing';
    } else {
      return 'stable';
    }
  }

  /// Calculate variance of values
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean)).toList();
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate trend strength (how consistent the trend is)
  double _calculateTrendStrength(List<double> values) {
    if (values.length < 3) return 0.0;
    
    // Calculate correlation coefficient
    final indices = List.generate(values.length, (i) => i.toDouble());
    final meanX = indices.reduce((a, b) => a + b) / indices.length;
    final meanY = values.reduce((a, b) => a + b) / values.length;
    
    double numerator = 0.0;
    double sumXSquared = 0.0;
    double sumYSquared = 0.0;
    
    for (int i = 0; i < values.length; i++) {
      final xDiff = indices[i] - meanX;
      final yDiff = values[i] - meanY;
      numerator += xDiff * yDiff;
      sumXSquared += xDiff * xDiff;
      sumYSquared += yDiff * yDiff;
    }
    
    final denominator = (sumXSquared * sumYSquared);
    if (denominator == 0) return 0.0;
    
    final correlation = numerator / (denominator);
    return correlation.abs(); // Return absolute value as strength
  }

  /// Calculate confidence score (0.0 to 1.0)
  double _calculateConfidence({
    required int dataPoints,
    required double variance,
    required double trendStrength,
  }) {
    // Base confidence from data points (more data = higher confidence)
    final dataConfidence = (dataPoints / 30).clamp(0.0, 1.0);
    
    // Variance factor (lower variance = higher confidence)
    final avgAmount = 100000.0; // Assume average daily expense
    final varianceFactor = (1 - (variance / (avgAmount * avgAmount)).clamp(0.0, 1.0));
    
    // Trend strength factor
    final trendFactor = trendStrength.clamp(0.0, 1.0);
    
    // Weighted average
    final confidence = (dataConfidence * 0.4) + 
                      (varianceFactor * 0.3) + 
                      (trendFactor * 0.3);
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Get human-readable trend message
  String _getTrendMessage(String trend, double confidence) {
    final confidencePercent = (confidence * 100).toStringAsFixed(0);
    
    switch (trend) {
      case 'increasing':
        return 'Pengeluaran cenderung meningkat. Prediksi dengan tingkat kepercayaan $confidencePercent%';
      case 'decreasing':
        return 'Pengeluaran cenderung menurun. Prediksi dengan tingkat kepercayaan $confidencePercent%';
      case 'stable':
        return 'Pengeluaran relatif stabil. Prediksi dengan tingkat kepercayaan $confidencePercent%';
      default:
        return 'Prediksi dengan tingkat kepercayaan $confidencePercent%';
    }
  }

  /// Predict expenses by category for next 30 days
  Future<Map<String, Money>> predictByCategory({
    required List<Map<String, dynamic>> transactions,
  }) async {
    final predictions = <String, Money>{};
    
    // Group by category
    final categoryGroups = <String, List<double>>{};
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    for (var transaction in transactions) {
      try {
        final date = DateTime.parse(transaction['date'] ?? '');
        final type = transaction['type']?.toString().toLowerCase() ?? 'expense';
        if (!date.isAfter(thirtyDaysAgo) || type != 'expense') continue;
        
        final category = transaction['category_name']?.toString() ?? 'Lainnya';
        final amount = (transaction['amount'] ?? 0).toDouble();
        
        categoryGroups.putIfAbsent(category, () => []).add(amount);
      } catch (e) {
        continue;
      }
    }
    
    // Predict for each category
    for (var entry in categoryGroups.entries) {
      final category = entry.key;
      final amounts = entry.value;
      
      if (amounts.length < 2) continue;
      
      final movingAvg = _calculateMovingAverage(amounts, windowSize: 7);
      final trend = _detectTrend(amounts);
      
      double forecast;
      if (trend == 'increasing') {
        forecast = movingAvg * 1.05;
      } else if (trend == 'decreasing') {
        forecast = movingAvg * 0.95;
      } else {
        forecast = movingAvg;
      }
      
      predictions[category] = Money.fromInt(
        forecast.round(),
        isoCode: 'IDR',
      );
    }
    
    return predictions;
  }
}

