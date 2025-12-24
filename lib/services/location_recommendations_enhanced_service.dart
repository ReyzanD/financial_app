import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/location_intelligence_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Enhanced Location Recommendations Service dengan price comparisons, alternative suggestions, dan analytics
class LocationRecommendationsEnhancedService {
  final ApiService _apiService = ApiService();
  final LocationIntelligenceService _locationService =
      LocationIntelligenceService();

  /// Get location recommendations dengan price comparisons
  Future<List<Map<String, dynamic>>>
  getLocationRecommendationsWithPrices() async {
    try {
      final recommendations = await _locationService.generateLocationInsights();

      // Get transactions untuk price analysis
      final transactions = await _apiService.getTransactions(limit: 200);

      // Analyze prices per location
      final priceAnalysis = _analyzeLocationPrices(
        transactions as List<dynamic>,
      );

      // Enhance recommendations dengan price data
      final enhanced = <Map<String, dynamic>>[];
      for (var rec in recommendations) {
        // Get location name from metadata or title
        final locationName =
            rec.metadata?['location']?.toString() ??
            rec.title.replaceAll(RegExp(r'[^\w\s]'), '').trim();
        final priceData = priceAnalysis[locationName];

        enhanced.add({
          'recommendation': rec.toMap(),
          'price_data': priceData,
          'alternatives': await _getAlternativeLocations(
            locationName,
            priceAnalysis,
          ),
          'analytics': _getLocationAnalytics(
            locationName,
            transactions as List<dynamic>,
          ),
        });
      }

      return enhanced;
    } catch (e) {
      LoggerService.error(
        'Error getting location recommendations with prices',
        error: e,
      );
      return [];
    }
  }

  Map<String, Map<String, dynamic>> _analyzeLocationPrices(
    List<dynamic> transactions,
  ) {
    final locationPrices = <String, List<double>>{};
    final locationCategories = <String, String>{};

    for (var t in transactions) {
      final locationName =
          t['location_name_232143']?.toString() ??
          t['location_name']?.toString();
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      final category = t['category_name']?.toString() ?? 'Lainnya';
      final type = t['type']?.toString().toLowerCase() ?? 'expense';

      if (locationName != null && type == 'expense' && amount > 0) {
        locationPrices[locationName] ??= [];
        locationPrices[locationName]!.add(amount);
        locationCategories[locationName] = category;
      }
    }

    final analysis = <String, Map<String, dynamic>>{};
    locationPrices.forEach((location, prices) {
      if (prices.isNotEmpty) {
        prices.sort();
        final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
        final minPrice = prices.first;
        final maxPrice = prices.last;
        final medianPrice = prices[prices.length ~/ 2];

        analysis[location] = {
          'average': avgPrice,
          'min': minPrice,
          'max': maxPrice,
          'median': medianPrice,
          'count': prices.length,
          'category': locationCategories[location] ?? 'Lainnya',
        };
      }
    });

    return analysis;
  }

  Future<List<Map<String, dynamic>>> _getAlternativeLocations(
    String locationName,
    Map<String, Map<String, dynamic>> priceAnalysis,
  ) async {
    final alternatives = <Map<String, dynamic>>[];

    // Find locations with similar category but lower prices
    final currentPriceData = priceAnalysis[locationName];
    if (currentPriceData == null) return alternatives;

    final currentCategory = currentPriceData['category'] as String;
    final currentAvg = currentPriceData['average'] as double;

    priceAnalysis.forEach((location, data) {
      if (location != locationName &&
          data['category'] == currentCategory &&
          (data['average'] as double) < currentAvg * 0.9) {
        // At least 10% cheaper
        alternatives.add({
          'location': location,
          'price_data': data,
          'savings': currentAvg - (data['average'] as double),
          'savings_percentage':
              ((currentAvg - (data['average'] as double)) / currentAvg) * 100,
        });
      }
    });

    // Sort by savings
    alternatives.sort((a, b) {
      final savingsA = a['savings'] as double;
      final savingsB = b['savings'] as double;
      return savingsB.compareTo(savingsA);
    });

    return alternatives.take(3).toList();
  }

  Map<String, dynamic> _getLocationAnalytics(
    String locationName,
    List<dynamic> transactions,
  ) {
    final locationTransactions =
        transactions.where((t) {
          final locName =
              t['location_name_232143']?.toString() ??
              t['location_name']?.toString();
          return locName == locationName;
        }).toList();

    if (locationTransactions.isEmpty) {
      return {
        'total_visits': 0,
        'total_spent': 0.0,
        'average_per_visit': 0.0,
        'last_visit': null,
      };
    }

    double totalSpent = 0.0;
    DateTime? lastVisit;

    for (var t in locationTransactions) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      totalSpent += amount;

      try {
        final dateStr =
            t['transaction_date']?.toString() ?? t['date']?.toString();
        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          if (lastVisit == null || date.isAfter(lastVisit)) {
            lastVisit = date;
          }
        }
      } catch (e) {
        // Ignore date parsing errors
      }
    }

    return {
      'total_visits': locationTransactions.length,
      'total_spent': totalSpent,
      'average_per_visit': totalSpent / locationTransactions.length,
      'last_visit': lastVisit?.toIso8601String(),
    };
  }

  /// Get spending pattern analysis per location
  Future<Map<String, dynamic>> getLocationSpendingPatterns() async {
    try {
      final transactions = await _apiService.getTransactions(limit: 500);
      final patterns = <String, Map<String, dynamic>>{};

      // Group by location
      final locationGroups = <String, List<Map<String, dynamic>>>{};
      for (var t in transactions as List<dynamic>) {
        final locationName =
            t['location_name_232143']?.toString() ??
            t['location_name']?.toString();
        if (locationName != null) {
          locationGroups[locationName] ??= [];
          locationGroups[locationName]!.add({
            'amount': (t['amount'] as num?)?.toDouble() ?? 0.0,
            'date': t['transaction_date'] ?? t['date'],
            'category': t['category_name'] ?? 'Lainnya',
          });
        }
      }

      // Analyze patterns
      locationGroups.forEach((location, trans) {
        if (trans.length >= 3) {
          // Calculate trends
          trans.sort((a, b) {
            try {
              final dateA = DateTime.parse(a['date']?.toString() ?? '');
              final dateB = DateTime.parse(b['date']?.toString() ?? '');
              return dateA.compareTo(dateB);
            } catch (e) {
              return 0;
            }
          });

          final recent = trans.take(trans.length ~/ 2).toList();
          final older = trans.skip(trans.length ~/ 2).toList();

          final recentAvg =
              recent.map((t) => t['amount'] as double).reduce((a, b) => a + b) /
              recent.length;
          final olderAvg =
              older.map((t) => t['amount'] as double).reduce((a, b) => a + b) /
              older.length;

          patterns[location] = {
            'total_visits': trans.length,
            'total_spent': trans
                .map((t) => t['amount'] as double)
                .reduce((a, b) => a + b),
            'trend':
                recentAvg > olderAvg * 1.1
                    ? 'increasing'
                    : recentAvg < olderAvg * 0.9
                    ? 'decreasing'
                    : 'stable',
            'recent_average': recentAvg,
            'older_average': olderAvg,
          };
        }
      });

      return {'locations': patterns, 'total_locations': patterns.length};
    } catch (e) {
      LoggerService.error('Error getting location spending patterns', error: e);
      return {};
    }
  }
}
