import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/models/location_recommendation.dart';

class LocationIntelligenceService {
  final ApiService _apiService = ApiService();

  /// Generate intelligent location-based recommendations
  Future<List<LocationRecommendation>> generateLocationInsights() async {
    try {
      // Analyze user's transaction locations
      final transactions = await _apiService.getTransactions(limit: 200);

      // Filter transactions with location data
      final locatedTransactions =
          transactions.where((t) {
            return t['location_name'] != null || t['latitude'] != null;
          }).toList();

      if (locatedTransactions.isEmpty) {
        return _getDefaultRecommendations();
      }

      // Analyze patterns
      final analysis = _analyzeLocationPatterns(locatedTransactions);

      // Generate smart recommendations
      final recommendations = _generateRecommendations(analysis);

      return recommendations;
    } catch (e) {
      print('Error generating location insights: $e');
      return _getDefaultRecommendations();
    }
  }

  Map<String, dynamic> _analyzeLocationPatterns(List<dynamic> transactions) {
    // Group by location
    Map<String, List<Map<String, dynamic>>> locationGroups = {};
    Map<String, double> locationTotals = {};
    Map<String, int> locationCounts = {};
    Map<String, String> locationCategories = {};

    for (var transaction in transactions) {
      final locationName =
          transaction['location_name']?.toString() ??
          transaction['notes']?.toString() ??
          'Unknown Location';

      final amount = (transaction['amount'] ?? 0).toDouble();
      final category = transaction['category_name']?.toString() ?? 'Lainnya';
      final type = transaction['type']?.toString().toLowerCase() ?? 'expense';

      if (type == 'expense') {
        locationGroups[locationName] ??= [];
        locationGroups[locationName]!.add({
          'amount': amount,
          'category': category,
          'date': transaction['date'],
        });

        locationTotals[locationName] =
            (locationTotals[locationName] ?? 0) + amount;
        locationCounts[locationName] = (locationCounts[locationName] ?? 0) + 1;
        locationCategories[locationName] = category;
      }
    }

    // Find top spending locations
    final sortedLocations =
        locationTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Find frequent locations
    final sortedByFrequency =
        locationCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate average spending per location
    Map<String, double> averageSpending = {};
    locationTotals.forEach((location, total) {
      averageSpending[location] = total / locationCounts[location]!;
    });

    // Find expensive locations (high average spending)
    final sortedByAverage =
        averageSpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'locationGroups': locationGroups,
      'locationTotals': locationTotals,
      'locationCounts': locationCounts,
      'locationCategories': locationCategories,
      'topSpendingLocations': sortedLocations,
      'mostFrequentLocations': sortedByFrequency,
      'expensiveLocations': sortedByAverage,
      'averageSpending': averageSpending,
      'totalLocations': locationGroups.length,
    };
  }

  List<LocationRecommendation> _generateRecommendations(
    Map<String, dynamic> analysis,
  ) {
    final recommendations = <LocationRecommendation>[];

    final topSpending = analysis['topSpendingLocations'] as List;
    final mostFrequent = analysis['mostFrequentLocations'] as List;
    final expensiveLocations = analysis['expensiveLocations'] as List;
    final locationTotals = analysis['locationTotals'] as Map<String, double>;
    final locationCounts = analysis['locationCounts'] as Map<String, int>;
    final locationCategories =
        analysis['locationCategories'] as Map<String, String>;

    // Recommendation 1: High spending location alert
    if (topSpending.isNotEmpty) {
      final topLocation = topSpending[0];
      final locationName = topLocation.key as String;
      final totalSpent = topLocation.value as double;
      final count = locationCounts[locationName] ?? 1;
      final category = locationCategories[locationName] ?? 'Lainnya';

      recommendations.add(
        LocationRecommendation(
          id: 'high_spending_1',
          title: '💰 Pengeluaran Tinggi di $locationName',
          description:
              'Anda telah menghabiskan Rp ${_formatCurrency(totalSpent)} di lokasi ini ($count transaksi). Coba cari alternatif lebih hemat di sekitar area.',
          type: RecommendationType.price_alert,
          estimatedSavings:
              (totalSpent * 0.15).toInt(), // Potential 15% savings
          createdAt: DateTime.now(),
          metadata: {
            'location': locationName,
            'totalSpent': totalSpent,
            'transactionCount': count,
            'category': category,
          },
        ),
      );
    }

    // Recommendation 2: Frequent location pattern
    if (mostFrequent.isNotEmpty && mostFrequent.length > 1) {
      final frequentLocation = mostFrequent[0];
      final locationName = frequentLocation.key as String;
      final visitCount = frequentLocation.value as int;
      final totalSpent = locationTotals[locationName] ?? 0;
      final avgSpent = totalSpent / visitCount;

      if (visitCount >= 5) {
        recommendations.add(
          LocationRecommendation(
            id: 'frequent_location_1',
            title: '📍 Lokasi Favorit: $locationName',
            description:
                'Anda sering belanja di sini ($visitCount kali) dengan rata-rata Rp ${_formatCurrency(avgSpent)}/transaksi. Pertimbangkan membership atau kartu loyalitas untuk diskon.',
            type: RecommendationType.spending_pattern,
            estimatedSavings:
                (avgSpent * visitCount * 0.10)
                    .toInt(), // 10% potential with loyalty
            createdAt: DateTime.now(),
            metadata: {
              'location': locationName,
              'visitCount': visitCount,
              'averageSpending': avgSpent,
              'totalSpent': totalSpent,
            },
          ),
        );
      }
    }

    // Recommendation 3: Expensive location per visit
    if (expensiveLocations.isNotEmpty) {
      final expensiveLocation = expensiveLocations[0];
      final locationName = expensiveLocation.key as String;
      final avgSpending = expensiveLocation.value as double;
      final visitCount = locationCounts[locationName] ?? 1;

      if (avgSpending > 100000) {
        // High average spending threshold
        recommendations.add(
          LocationRecommendation(
            id: 'expensive_location_1',
            title: '⚠️ Lokasi Mahal: $locationName',
            description:
                'Rata-rata pengeluaran Anda di lokasi ini Rp ${_formatCurrency(avgSpending)}/kunjungan. Coba bandingkan harga dengan lokasi lain di sekitar.',
            type: RecommendationType.alternative_location,
            estimatedSavings:
                (avgSpending * visitCount * 0.20).toInt(), // 20% potential
            createdAt: DateTime.now(),
            metadata: {
              'location': locationName,
              'averageSpending': avgSpending,
              'visitCount': visitCount,
            },
          ),
        );
      }
    }

    // Recommendation 4: Location diversity insight
    final totalLocations = analysis['totalLocations'] as int;
    if (totalLocations < 5) {
      recommendations.add(
        LocationRecommendation(
          id: 'diversity_1',
          title: '🗺️ Jelajahi Lebih Banyak Tempat',
          description:
              'Anda berbelanja di $totalLocations lokasi berbeda. Coba eksplorasi tempat lain untuk menemukan harga lebih murah dan variasi lebih banyak.',
          type: RecommendationType.general,
          estimatedSavings: 0,
          createdAt: DateTime.now(),
          metadata: {'currentLocationCount': totalLocations},
        ),
      );
    } else if (totalLocations > 15) {
      recommendations.add(
        LocationRecommendation(
          id: 'consolidate_1',
          title: '🎯 Konsolidasikan Belanja Anda',
          description:
              'Anda berbelanja di $totalLocations lokasi berbeda. Fokus pada 3-5 tempat terbaik untuk menghemat waktu dan dapat loyalty rewards.',
          type: RecommendationType.spending_pattern,
          estimatedSavings: 50000, // Time & potential loyalty savings
          createdAt: DateTime.now(),
          metadata: {'currentLocationCount': totalLocations},
        ),
      );
    }

    // Recommendation 5: Category-specific location advice
    final categoryLocationCounts = <String, Set<String>>{};
    locationCategories.forEach((location, category) {
      categoryLocationCounts[category] ??= {};
      categoryLocationCounts[category]!.add(location);
    });

    categoryLocationCounts.forEach((category, locations) {
      if (locations.length == 1 && locationCounts[locations.first]! > 5) {
        final location = locations.first;
        final spent = locationTotals[location] ?? 0;

        recommendations.add(
          LocationRecommendation(
            id: 'category_${category}_1',
            title: '🏪 Alternatif untuk $category',
            description:
                'Semua pengeluaran $category Anda di $location (Rp ${_formatCurrency(spent)}). Coba bandingkan dengan tempat lain untuk potensi hemat 15-25%.',
            type: RecommendationType.alternative_location,
            estimatedSavings: (spent * 0.20).toInt(),
            createdAt: DateTime.now(),
            metadata: {
              'category': category,
              'location': location,
              'totalSpent': spent,
            },
          ),
        );
      }
    });

    // Return top 3 most valuable recommendations
    recommendations.sort(
      (a, b) => b.estimatedSavings.compareTo(a.estimatedSavings),
    );
    return recommendations.take(3).toList();
  }

  List<LocationRecommendation> _getDefaultRecommendations() {
    return [
      LocationRecommendation(
        id: 'default_1',
        title: '📍 Mulai Catat Lokasi Transaksi',
        description:
            'Tambahkan informasi lokasi saat mencatat transaksi untuk mendapat rekomendasi tempat belanja lebih hemat.',
        type: RecommendationType.general,
        estimatedSavings: 0,
        createdAt: DateTime.now(),
        metadata: {},
      ),
      LocationRecommendation(
        id: 'default_2',
        title: '💡 Tips Hemat Belanja',
        description:
            'Bandingkan harga di beberapa tempat sebelum membeli. Pasar tradisional sering 20-30% lebih murah dari supermarket untuk kebutuhan sehari-hari.',
        type: RecommendationType.general,
        estimatedSavings: 0,
        createdAt: DateTime.now(),
        metadata: {},
      ),
    ];
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return amount.toStringAsFixed(0);
  }

  /// Get location-specific recommendations for a category
  Future<List<LocationRecommendation>> getCategoryLocationAdvice(
    String category,
  ) async {
    try {
      final transactions = await _apiService.getTransactions(limit: 100);

      // Filter by category
      final categoryTransactions =
          transactions.where((t) {
            final txCategory =
                t['category_name']?.toString().toLowerCase() ?? '';
            return txCategory.contains(category.toLowerCase());
          }).toList();

      if (categoryTransactions.isEmpty) {
        return [];
      }

      final analysis = _analyzeLocationPatterns(categoryTransactions);
      return _generateRecommendations(analysis);
    } catch (e) {
      print('Error getting category location advice: $e');
      return [];
    }
  }
}
