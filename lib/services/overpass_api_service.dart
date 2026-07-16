import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/osm_category_mapping_service.dart';
import 'package:financial_app/services/network_service.dart';
import 'package:financial_app/services/api_security_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Result from an Overpass API query.
class OverpassPoiResult {
  final String osmId;
  final String osmType; // "node" | "way" | "relation"
  final String name;
  final double latitude;
  final double longitude;
  final String? amenity;
  final String? shop;
  final String? cuisine;
  final String? openingHours;

  OverpassPoiResult({
    required this.osmId,
    required this.osmType,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.amenity,
    this.shop,
    this.cuisine,
    this.openingHours,
  });

  /// OSM node identifier in the form "node/12345".
  String get osmNodeId => '$osmType/$osmId';
}

/// Service for querying the OpenStreetMap Overpass API.
///
/// Overpass (https://overpass-api.de) provides a read-only API for
/// querying OSM data using Overpass QL. This service wraps the most
/// common query pattern: "find POIs matching category tags near a point".
///
/// **Usage limits** (free tier):
///   - 10,000 queries/day per IP
///   - Heavy queries may be throttled
///   - Cache aggressively to stay within limits
class OverpassApiService {
  final String _baseUrl = 'https://overpass-api.de/api/interpreter';
  final String _userAgent = 'FinancialApp/1.0 (financial.app.makassar)';

  /// Request timeout — Overpass can be slow for complex queries.
  static const Duration _timeout = Duration(seconds: 15);

  /// In-memory cache: key = "lat_lng_category" => (timestamp, results)
  static final Map<String, _CacheEntry<List<OverpassPoiResult>>> _cache = {};
  static const Duration _cacheDuration = Duration(hours: 24);

  final OsmCategoryMappingService _mappingService;
  final NetworkService _networkService;
  final ApiSecurityService _apiSecurityService;

  OverpassApiService({
    OsmCategoryMappingService? mappingService,
    NetworkService? networkService,
    ApiSecurityService? apiSecurityService,
  }) : _mappingService = mappingService ?? OsmCategoryMappingService(),
       _networkService = networkService ?? getIt<NetworkService>(),
       _apiSecurityService = apiSecurityService ?? getIt<ApiSecurityService>();

  /// Find nearby POIs matching the given category around a location.
  ///
  /// [latitude], [longitude] — center point in decimal degrees.
  /// [categoryName] — app category name (e.g. "Makanan & Minuman").
  /// [radiusMeters] — search radius (default 1000m, max 5000m).
  /// [maxResults] — max POIs to return (default 10, max 50).
  /// [forceRefresh] — bypass cache.
  Future<List<OverpassPoiResult>> findNearbyPois({
    required double latitude,
    required double longitude,
    required String categoryName,
    int radiusMeters = 1000,
    int maxResults = 10,
    bool forceRefresh = false,
  }) async {
    // Clamp inputs
    radiusMeters = radiusMeters.clamp(100, 5000);
    maxResults = maxResults.clamp(1, 50);

    // Round coords to ~100m precision for cache key (prevents cache explosion)
    final cacheLat = (latitude * 1000).round() / 1000;
    final cacheLng = (longitude * 1000).round() / 1000;
    final cacheKey = '${cacheLat}_${cacheLng}_${categoryName}_$radiusMeters';

    // Check cache
    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null &&
          DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        LoggerService.cache('HIT', 'overpass_$cacheKey');
        return cached.data;
      }
    }

    // Respect fair use: skip the network entirely when offline (callers fall
    // back to any cached suggestions) and when the per-endpoint rate limit is
    // exceeded. Overpass is a free, shared public service.
    if (!_networkService.isOnline) {
      LoggerService.warning(
        'Overpass skipped: device offline (serving cache only)',
      );
      return [];
    }
    final withinRateLimit = await _apiSecurityService.checkRateLimit(
      'overpass',
    );
    if (!withinRateLimit) {
      LoggerService.warning(
        'Overpass skipped: rate limit exceeded for endpoint "overpass"',
      );
      return [];
    }

    // Build Overpass QL query
    final tagFilters = _mappingService.buildOverpassFilter(categoryName);
    final bboxLatMin = latitude - (radiusMeters / 111300.0);
    final bboxLatMax = latitude + (radiusMeters / 111300.0);
    final bboxLngMin = longitude - (radiusMeters / (111300.0 * _cos(latitude)));
    final bboxLngMax = longitude + (radiusMeters / (111300.0 * _cos(latitude)));

    // Overpass QL: find nodes and ways with matching tags in bounding box
    final query = '''
[out:json][timeout:15];
(
  node$tagFilters($bboxLatMin,$bboxLngMin,$bboxLatMax,$bboxLngMax);
  way$tagFilters($bboxLatMin,$bboxLngMin,$bboxLatMax,$bboxLngMax);
);
out center $maxResults;
''';

    try {
      LoggerService.info(
        '🔍 Overpass query: $categoryName @ ($latitude, $longitude) '
        'radius=${radiusMeters}m',
      );

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'User-Agent': _userAgent,
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=utf-8',
            },
            body: {'data': query},
          )
          .timeout(
            _timeout,
            onTimeout: () => throw Exception('Overpass API request timeout'),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Overpass API error: ${response.statusCode} - '
          '${response.body.substring(0, response.body.length.clamp(0, 200))}',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List? ?? [];
      final results = <OverpassPoiResult>[];

      for (final element in elements) {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name']?.toString() ?? _unknownName(element);

        // Skip nameless elements (not useful as recommendations)
        if (name.isEmpty || name.startsWith('_') || _isGenericName(name)) {
          continue;
        }

        double? lat;
        double? lon;

        if (element['type'] == 'node') {
          lat = (element['lat'] as num?)?.toDouble();
          lon = (element['lon'] as num?)?.toDouble();
        } else if (element['type'] == 'way') {
          final center = element['center'] as Map<String, dynamic>?;
          if (center != null) {
            lat = (center['lat'] as num?)?.toDouble();
            lon = (center['lon'] as num?)?.toDouble();
          }
        }

        if (lat == null || lon == null) continue;

        results.add(
          OverpassPoiResult(
            osmId: element['id'].toString(),
            osmType: element['type'] as String? ?? 'node',
            name: name,
            latitude: lat,
            longitude: lon,
            amenity: tags['amenity']?.toString(),
            shop: tags['shop']?.toString(),
            cuisine: tags['cuisine']?.toString(),
            openingHours: tags['opening_hours']?.toString(),
          ),
        );
      }

      // Cache results
      _cache[cacheKey] = _CacheEntry(data: results, timestamp: DateTime.now());

      LoggerService.info(
        '✅ Overpass found ${results.length} POIs for "$categoryName"',
      );
      return results;
    } catch (e) {
      LoggerService.error('Overpass API query failed', error: e);
      rethrow;
    }
  }

  /// Generate a fallback name from element metadata.
  String _unknownName(Map<String, dynamic> element) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    return tags['amenity']?.toString() ??
        tags['shop']?.toString() ??
        tags['cuisine']?.toString() ??
        'Unknown ${element['type']} ${element['id']}';
  }

  /// Skip very generic OSM names that aren't useful as suggestions.
  bool _isGenericName(String name) {
    const generics = [
      'restaurant',
      'cafe',
      'shop',
      'supermarket',
      'toko',
      'warung',
      'building',
      'entrance',
      'address',
    ];
    return generics.contains(name.toLowerCase());
  }

  /// Cosine approximation for latitude correction in bounding box.
  double _cos(double degrees) {
    final rad = degrees * 0.017453292519943295; // pi/180
    final x = rad;
    // Taylor series cos(x) ≈ 1 - x²/2 + x⁴/24
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }

  /// Clear the in-memory cache.
  static void clearCache() {
    _cache.clear();
    LoggerService.cache('CLEARED', 'overpass_cache');
  }
}

/// Internal cache entry.
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});
}
