import 'package:money2/money2.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service for statistical expense forecasting using moving average and trend analysis
/// Provides on-device ML capabilities without external dependencies
class ExpensePredictor {
  /// Predict expenses for the next N days based on historical data
  /// Returns forecast as Money object with confidence score and confidence intervals
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
          'confidence_interval': {'lower': 0.0, 'upper': 0.0},
        };
      }

      // Filter last 90 days for better analysis (3 months)
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));
      final recentExpenses =
          transactions.where((t) {
            try {
              final dateStr =
                  t['transaction_date']?.toString() ??
                  t['date']?.toString() ??
                  '';
              if (dateStr.isEmpty) return false;
              final date = DateTime.parse(dateStr);
              final type = t['type']?.toString().toLowerCase() ?? 'expense';
              return date.isAfter(ninetyDaysAgo) && type == 'expense';
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
          'confidence_interval': {'lower': 0.0, 'upper': 0.0},
        };
      }

      // Extract daily amounts
      final dailyAmounts = _groupByDay(recentExpenses);
      final amounts = dailyAmounts.values.toList();

      // Multi-algorithm prediction
      final movingAvgForecast = _predictMovingAverage(amounts);
      final exponentialSmoothingForecast = _predictExponentialSmoothing(
        amounts,
      );
      final regressionForecast = _predictLinearRegression(amounts);

      // Seasonal adjustment
      final seasonalFactor = _calculateSeasonalFactor(recentExpenses, now);

      // Combine predictions with weights
      final combinedForecast =
          (movingAvgForecast * 0.4 +
              exponentialSmoothingForecast * 0.35 +
              regressionForecast * 0.25) *
          seasonalFactor;

      // Detect trend
      final trend = _detectTrend(amounts);

      // Apply trend adjustment
      double finalForecast = combinedForecast;
      if (trend == 'increasing') {
        finalForecast *= 1.03; // 3% growth
      } else if (trend == 'decreasing') {
        finalForecast *= 0.97; // 3% reduction
      }

      final forecastMoney = Money.fromInt(
        finalForecast.round(),
        isoCode: 'IDR',
      );

      // Calculate confidence based on data quality
      final confidence = _calculateConfidence(
        dataPoints: amounts.length,
        variance: _calculateVariance(amounts),
        trendStrength: _calculateTrendStrength(amounts),
      );

      // Calculate confidence intervals (95% confidence)
      final stdDev = _calculateStandardDeviation(amounts);
      final marginOfError = stdDev * 1.96; // 95% confidence interval
      final lowerBound = (finalForecast - marginOfError).clamp(
        0.0,
        double.infinity,
      );
      final upperBound = finalForecast + marginOfError;

      LoggerService.debug(
        '[ExpensePredictor] Forecast: ${forecastMoney.toString()}, Confidence: ${(confidence * 100).toStringAsFixed(1)}%, Range: ${lowerBound.toInt()} - ${upperBound.toInt()}',
      );

      return {
        'forecast': forecastMoney,
        'forecastAmount': forecastMoney.minorUnits.toDouble(),
        'confidence': confidence,
        'trend': trend,
        'message': _getTrendMessage(trend, confidence),
        'confidence_interval': {
          'lower': lowerBound,
          'upper': upperBound,
          'lower_money': Money.fromInt(lowerBound.round(), isoCode: 'IDR'),
          'upper_money': Money.fromInt(upperBound.round(), isoCode: 'IDR'),
        },
        'seasonal_factor': seasonalFactor,
        'algorithms': {
          'moving_average': movingAvgForecast,
          'exponential_smoothing': exponentialSmoothingForecast,
          'linear_regression': regressionForecast,
        },
      };
    } catch (e) {
      LoggerService.error('Error predicting expenses', error: e);
      return {
        'forecast': Money.fromInt(0, isoCode: 'IDR'),
        'forecastAmount': 0.0,
        'confidence': 0.0,
        'trend': 'error',
        'message': 'Terjadi kesalahan saat memprediksi pengeluaran',
        'confidence_interval': {'lower': 0.0, 'upper': 0.0},
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

  /// Predict using moving average method
  double _predictMovingAverage(List<double> amounts) {
    return _calculateMovingAverage(amounts, windowSize: 7);
  }

  /// Predict using exponential smoothing method
  double _predictExponentialSmoothing(
    List<double> amounts, {
    double alpha = 0.3,
  }) {
    if (amounts.isEmpty) return 0.0;
    if (amounts.length == 1) return amounts.first;

    double smoothed = amounts.first;
    for (int i = 1; i < amounts.length; i++) {
      smoothed = alpha * amounts[i] + (1 - alpha) * smoothed;
    }
    return smoothed;
  }

  /// Predict using linear regression method
  double _predictLinearRegression(List<double> amounts) {
    if (amounts.length < 2) return amounts.isNotEmpty ? amounts.first : 0.0;

    final n = amounts.length;
    final indices = List.generate(n, (i) => i.toDouble());

    final sumX = indices.reduce((a, b) => a + b);
    final sumY = amounts.reduce((a, b) => a + b);
    final sumXY = indices
        .asMap()
        .entries
        .map((e) => e.value * amounts[e.key])
        .reduce((a, b) => a + b);
    final sumX2 = indices.map((x) => x * x).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Predict next value (n+1)
    return slope * n + intercept;
  }

  /// Calculate seasonal adjustment factor
  /// Accounts for holidays, paydays, and monthly patterns
  double _calculateSeasonalFactor(
    List<Map<String, dynamic>> expenses,
    DateTime now,
  ) {
    double factor = 1.0;

    // Check if we're near end of month (typically higher spending)
    final dayOfMonth = now.day;
    if (dayOfMonth >= 25) {
      factor *= 1.1; // 10% increase near month end
    } else if (dayOfMonth <= 5) {
      factor *= 0.95; // 5% decrease at start of month
    }

    // Check for holiday months (December, January, etc.)
    final month = now.month;
    if (month == 12) {
      factor *= 1.15; // 15% increase in December (holidays)
    } else if (month == 1) {
      factor *= 1.1; // 10% increase in January (New Year)
    }

    // Check day of week (weekends typically have higher spending)
    final weekday = now.weekday;
    if (weekday == 6 || weekday == 7) {
      factor *= 1.05; // 5% increase on weekends
    }

    return factor;
  }

  /// Calculate standard deviation
  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean)).toList();
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;

    return variance > 0 ? variance : 0.0;
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
    final varianceFactor =
        (1 - (variance / (avgAmount * avgAmount)).clamp(0.0, 1.0));

    // Trend strength factor
    final trendFactor = trendStrength.clamp(0.0, 1.0);

    // Weighted average
    final confidence =
        (dataConfidence * 0.4) + (varianceFactor * 0.3) + (trendFactor * 0.3);

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

      predictions[category] = Money.fromInt(forecast.round(), isoCode: 'IDR');
    }

    return predictions;
  }
}
