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

  // Method to get category-specific alternative recommendations
  Future<List<LocationRecommendation>> getCategoryBasedAlternatives(
    String category,
    Map<String, dynamic>? locationData,
  ) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock recommendations based on category
    switch (category.toLowerCase()) {
      case 'belanja':
        return [
          LocationRecommendation(
            id: 'alt_shop_1',
            title: 'Diskon 25% di Toko Sebelah',
            description:
                'Toko grosir di Jl. Malioboro menawarkan produk serupa dengan diskon hingga 25%',
            type: RecommendationType.price_alert,
            estimatedSavings: 75000,
            createdAt: DateTime.now(),
            metadata: {
              'location': 'Toko Grosir Malioboro',
              'distance': '1.2 km',
              'discount': '25%',
              'category': 'shopping',
            },
          ),
          LocationRecommendation(
            id: 'alt_shop_2',
            title: 'Pasar Tradisional Lebih Murah',
            description:
                'Pasar tradisional menawarkan harga 30% lebih rendah untuk kebutuhan sehari-hari',
            type: RecommendationType.alternative_location,
            estimatedSavings: 45000,
            createdAt: DateTime.now(),
            metadata: {
              'location': 'Pasar Tradisional Ngasem',
              'distance': '0.8 km',
              'savingsPercentage': 30,
              'category': 'shopping',
            },
          ),
        ];

      case 'transportasi':
        return [
          LocationRecommendation(
            id: 'alt_transport_1',
            title: 'Bensin Lebih Murah 3km Jauhnya',
            description:
                'SPBU di Jl. Sudirman menawarkan harga premium Rp 2.000 lebih murah per liter',
            type: RecommendationType.price_alert,
            estimatedSavings: 10000,
            createdAt: DateTime.now(),
            metadata: {
              'location': 'SPBU Sudirman',
              'distance': '3.1 km',
              'priceDifference': 2000,
              'category': 'fuel',
            },
          ),
          LocationRecommendation(
            id: 'alt_transport_2',
            title: 'Alternatif Transportasi Hemat',
            description:
                'Gunakan angkutan umum untuk perjalanan ini, bisa hemat hingga Rp 15.000',
            type: RecommendationType.alternative_location,
            estimatedSavings: 15000,
            createdAt: DateTime.now(),
            metadata: {
              'location': 'Halte Bus Terdekat',
              'distance': '0.3 km',
              'category': 'public_transport',
            },
          ),
        ];

      case 'makanan':
      case 'restoran':
        return [
          LocationRecommendation(
            id: 'alt_food_1',
            title: 'Warung Makan Diskon Siang',
            description:
                'Warung makan di dekat sini menawarkan diskon 20% untuk makan siang',
            type: RecommendationType.price_alert,
            estimatedSavings: 20000,
            createdAt: DateTime.now(),
            metadata: {
              'location': 'Warung Bu Siti',
              'distance': '0.5 km',
              'discount': '20%',
              'time': 'lunch',
              'category': 'food',
            },
          ),
          LocationRecommendation(
            id: 'alt_food_2',
            title: 'Restoran Padang Promo',
            description:
                'Restoran Padang menawarkan paket makan dengan harga Rp 25.000 (normal Rp 35.000)',
            type: RecommendationType.alternative_location,
            estimatedSavings: 10000,
            createdAt: DateTime.now(),
            metadata: {
              'location': 'Restoran Padang Minang',
              'distance': '1.0 km',
              'originalPrice': 35000,
              'promoPrice': 25000,
              'category': 'food',
            },
          ),
        ];

      case 'tagihan':
        return [
          LocationRecommendation(
            id: 'alt_bill_1',
            title: 'Pembayaran Online Lebih Murah',
            description:
                'Bayar tagihan listrik via aplikasi digital untuk dapat potongan biaya admin Rp 2.500',
            type: RecommendationType.price_alert,
            estimatedSavings: 2500,
            createdAt: DateTime.now(),
            metadata: {
              'location': 'Aplikasi PLN Mobile',
              'distance': '0 km',
              'adminFeeSavings': 2500,
              'category': 'bills',
            },
          ),
        ];

      default:
        return [
          LocationRecommendation(
            id: 'alt_general_1',
            title: 'Cek Promo di Aplikasi',
            description:
                'Banyak tempat menawarkan diskon melalui aplikasi. Cek aplikasi favorit Anda!',
            type: RecommendationType.general,
            estimatedSavings: 0,
            createdAt: DateTime.now(),
            metadata: {
              'location': 'Aplikasi Promo',
              'distance': '0 km',
              'category': 'general',
            },
          ),
        ];
    }
  }
}
