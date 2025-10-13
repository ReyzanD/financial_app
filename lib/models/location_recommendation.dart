enum RecommendationType {
  price_alert,
  alternative_location,
  spending_pattern,
  general,
}

class LocationRecommendation {
  final String id;
  final String title;
  final String description;
  final RecommendationType type;
  final int estimatedSavings;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const LocationRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.estimatedSavings = 0,
    required this.createdAt,
    this.metadata,
  });

  factory LocationRecommendation.fromMap(Map<String, dynamic> map) {
    return LocationRecommendation(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: RecommendationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RecommendationType.general,
      ),
      estimatedSavings: map['estimatedSavings'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'estimatedSavings': estimatedSavings,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class LocationRecommendationService {
  // Mock service for location-based recommendations
  Future<List<LocationRecommendation>> getDailyLocationInsights() async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock data - in real app, this would come from backend
    return [
      LocationRecommendation(
        id: '1',
        title: 'Harga Bensin Lebih Murah 2km dari Lokasi Biasa',
        description:
            'SPBU di Jl. Sudirman menawarkan harga premium 2rb lebih murah per liter',
        type: RecommendationType.price_alert,
        estimatedSavings: 10000,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        metadata: {
          'location': 'Jl. Sudirman No. 45',
          'distance': '2.1 km',
          'priceDifference': 2000,
        },
      ),
      LocationRecommendation(
        id: '2',
        title: 'Alternatif Supermarket Hemat',
        description:
            'Toko kelontong di sekitar rumah Anda 15% lebih murah untuk kebutuhan sehari-hari',
        type: RecommendationType.alternative_location,
        estimatedSavings: 25000,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        metadata: {
          'location': 'Jl. Mawar No. 12',
          'distance': '0.8 km',
          'savingsPercentage': 15,
        },
      ),
      LocationRecommendation(
        id: '3',
        title: 'Pola Belanja Anda Efisien',
        description:
            'Belanja bulanan Anda turun 8% dibanding bulan lalu. Pertahankan!',
        type: RecommendationType.spending_pattern,
        estimatedSavings: 0, // No direct savings, just positive feedback
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        metadata: {'trend': 'decreasing', 'percentageChange': -8},
      ),
    ];
  }

  // Method to get recommendations based on user location
  Future<List<LocationRecommendation>> getLocationBasedRecommendations(
    double latitude,
    double longitude,
  ) async {
    // In real implementation, this would call a backend API
    // with user's current location to get nearby recommendations
    await Future.delayed(const Duration(seconds: 1));

    return [
      LocationRecommendation(
        id: 'nearby_1',
        title: 'Restoran Terdekat Lebih Murah',
        description:
            'Warung makan di dekat kantor Anda menawarkan menu serupa dengan harga 20% lebih rendah',
        type: RecommendationType.price_alert,
        estimatedSavings: 15000,
        createdAt: DateTime.now(),
        metadata: {
          'location': 'Warung Bu Siti',
          'distance': '0.5 km',
          'category': 'food',
        },
      ),
    ];
  }
}
