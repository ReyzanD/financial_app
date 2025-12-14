import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:financial_app/services/logger_service.dart';

enum MapProvider {
  maptiler,
  mapbox,
  openstreetmap,
}

class MapProviderService {
  static MapProvider _currentProvider = MapProvider.maptiler;
  static String? _maptilerApiKey;
  static String? _mapboxAccessToken;
  static bool _initialized = false;

  // Cache for geocoding results (24 hours)
  static final Map<String, List<Map<String, dynamic>>> _geocodingCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Initialize the service (call this in main.dart)
  /// Pass env map from dotenv to avoid import issues
  static Future<void> initialize([Map<String, String>? env]) async {
    if (_initialized) return;

    try {
      // Try to load API keys from env map
      if (env != null) {
        _maptilerApiKey = env['MAPTILER_API_KEY'];
        _mapboxAccessToken = env['MAPBOX_ACCESS_TOKEN'];
        
        // Debug logging
        LoggerService.debug(
          '[MapProvider] Env map loaded: ${env.keys.length} keys',
        );
        LoggerService.debug(
          '[MapProvider] MAPTILER_API_KEY found: ${_maptilerApiKey != null && _maptilerApiKey!.isNotEmpty}',
        );
        LoggerService.debug(
          '[MapProvider] MAPBOX_ACCESS_TOKEN found: ${_mapboxAccessToken != null && _mapboxAccessToken!.isNotEmpty}',
        );
      } else {
        LoggerService.warning('[MapProvider] Env map is null');
      }
      
      // Priority: MapTiler > Mapbox > OpenStreetMap
      if (_maptilerApiKey != null && _maptilerApiKey!.isNotEmpty) {
        _currentProvider = MapProvider.maptiler;
        LoggerService.info(
          '[MapProvider] Using MapTiler as primary provider',
        );
      } else if (_mapboxAccessToken != null && _mapboxAccessToken!.isNotEmpty) {
        _currentProvider = MapProvider.mapbox;
        LoggerService.info('[MapProvider] Using Mapbox as primary provider');
      } else {
        _currentProvider = MapProvider.openstreetmap;
        LoggerService.info(
          '[MapProvider] No API keys found, using OpenStreetMap',
        );
      }
      _initialized = true;
    } catch (e) {
      LoggerService.warning(
        '[MapProvider] Error initializing, using OpenStreetMap: $e',
      );
      _currentProvider = MapProvider.openstreetmap;
      _initialized = true;
    }
  }

  /// Get tile URL based on current provider
  static String getTileUrl(int z, int x, int y) {
    if (_currentProvider == MapProvider.maptiler && _maptilerApiKey != null) {
      return 'https://api.maptiler.com/maps/streets-v2/$z/$x/$y.png?key=$_maptilerApiKey';
    }
    if (_currentProvider == MapProvider.mapbox && _mapboxAccessToken != null) {
      return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/$z/$x/$y@2x?access_token=$_mapboxAccessToken';
    }
    // Fallback to OSM
    return 'https://tile.openstreetmap.org/$z/$x/$y.png';
  }

  /// Get tile layer URL template for flutter_map
  static String getTileUrlTemplate() {
    if (_currentProvider == MapProvider.maptiler && _maptilerApiKey != null) {
      return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$_maptilerApiKey';
    }
    if (_currentProvider == MapProvider.mapbox && _mapboxAccessToken != null) {
      return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$_mapboxAccessToken';
    }
    // Fallback to OSM
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// Search location with automatic fallback
  static Future<List<Map<String, dynamic>>> searchLocation(
    String query, {
    String? countryCode = 'id',
    int limit = 5,
  }) async {
    // Check cache first
    final cacheKey = '${query}_$countryCode';
    if (_geocodingCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        LoggerService.cache('HIT', 'geocoding_$cacheKey');
        return _geocodingCache[cacheKey]!;
      }
    }

    List<Map<String, dynamic>> results = [];

    // Try MapTiler first if available
    if (_currentProvider == MapProvider.maptiler && _maptilerApiKey != null) {
      try {
        results = await _searchMapTiler(query, countryCode, limit);
        if (results.isNotEmpty) {
          LoggerService.info(
            '[MapProvider] Found ${results.length} results from MapTiler',
          );
          _cacheResult(cacheKey, results);
          return results;
        }
      } catch (e) {
        LoggerService.warning(
          '[MapProvider] MapTiler search failed, trying fallback: $e',
        );
      }
    }

    // Try Mapbox if available
    if (_currentProvider == MapProvider.mapbox &&
        _mapboxAccessToken != null) {
      try {
        results = await _searchMapbox(query, countryCode, limit);
        if (results.isNotEmpty) {
          LoggerService.info(
            '[MapProvider] Found ${results.length} results from Mapbox',
          );
          _cacheResult(cacheKey, results);
          return results;
        }
      } catch (e) {
        LoggerService.warning(
          '[MapProvider] Mapbox search failed, trying fallback: $e',
        );
      }
    }

    // Fallback to OpenStreetMap
    try {
      results = await _searchOpenStreetMap(query, countryCode, limit);
      if (results.isNotEmpty) {
        LoggerService.info(
          '[MapProvider] Found ${results.length} results from OpenStreetMap',
        );
        _cacheResult(cacheKey, results);
        return results;
      }
    } catch (e) {
      LoggerService.error(
        '[MapProvider] OpenStreetMap search also failed: $e',
        error: e,
      );
    }

    LoggerService.warning('[MapProvider] No results found for: $query');
    return [];
  }

  /// Search using MapTiler Geocoding API
  static Future<List<Map<String, dynamic>>> _searchMapTiler(
    String query,
    String? countryCode,
    int limit,
  ) async {
    if (_maptilerApiKey == null) {
      throw Exception('MapTiler API key not available');
    }

    final encodedQuery = Uri.encodeComponent(query);
    final countryParam = countryCode != null ? '&country=$countryCode' : '';
    final url = Uri.parse(
      'https://api.maptiler.com/geocoding/$encodedQuery.json?'
      'key=$_maptilerApiKey'
      '$countryParam'
      '&limit=$limit',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('MapTiler request timeout'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List?;

      if (features == null || features.isEmpty) {
        return [];
      }

      return features.map((feature) {
        final geometry = feature['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List;
        final properties = feature['properties'] as Map<String, dynamic>;
        
        return {
          'lat': (coordinates[1] as num).toDouble(),
          'lng': (coordinates[0] as num).toDouble(),
          'displayName': properties['name'] as String? ?? 
                        properties['place_name'] as String? ?? 
                        query,
          'type': properties['type'] as String? ?? 'place',
        };
      }).toList();
    } else {
      throw Exception(
        'MapTiler API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Search using Mapbox Geocoding API
  static Future<List<Map<String, dynamic>>> _searchMapbox(
    String query,
    String? countryCode,
    int limit,
  ) async {
    if (_mapboxAccessToken == null) {
      throw Exception('Mapbox access token not available');
    }

    final encodedQuery = Uri.encodeComponent(query);
    final countryParam = countryCode != null ? '&country=$countryCode' : '';
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json?'
      'access_token=$_mapboxAccessToken'
      '$countryParam'
      '&limit=$limit',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Mapbox request timeout'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final features = data['features'] as List?;

      if (features == null || features.isEmpty) {
        return [];
      }

      return features.map((feature) {
        final center = feature['center'] as List;
        return {
          'lat': (center[1] as num).toDouble(),
          'lng': (center[0] as num).toDouble(),
          'displayName': feature['place_name'] as String? ?? query,
          'type': (feature['place_type'] as List?)?[0] as String? ?? 'place',
        };
      }).toList();
    } else {
      throw Exception(
        'Mapbox API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Search using OpenStreetMap Nominatim API
  static Future<List<Map<String, dynamic>>> _searchOpenStreetMap(
    String query,
    String? countryCode,
    int limit,
  ) async {
    // Add location context for better results in Indonesia
    final searchQuery = query.toLowerCase().contains('makassar') ||
            query.toLowerCase().contains('indonesia')
        ? query
        : '$query, Makassar, Sulawesi Selatan, Indonesia';

    final encodedQuery = Uri.encodeComponent(searchQuery);
    final countryParam =
        countryCode != null ? '&countrycodes=$countryCode' : '';
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$encodedQuery'
      '&format=json'
      '&limit=$limit'
      '$countryParam',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'FinancialApp/1.0 (financial.app.makassar)',
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Nominatim request timeout'),
    );

    if (response.statusCode == 200) {
      final results = json.decode(response.body) as List;

      if (results.isEmpty) {
        return [];
      }

      return results.map((result) {
        return {
          'lat': double.parse(result['lat'] as String),
          'lng': double.parse(result['lon'] as String),
          'displayName': result['display_name'] as String,
          'type': result['type'] as String? ?? 'place',
        };
      }).toList();
    } else {
      throw Exception(
        'Nominatim API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Cache geocoding result
  static void _cacheResult(String key, List<Map<String, dynamic>> results) {
    _geocodingCache[key] = results;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Clear geocoding cache
  static void clearCache() {
    _geocodingCache.clear();
    _cacheTimestamps.clear();
    LoggerService.cache('CLEARED', 'geocoding_cache');
  }

  /// Get current provider
  static MapProvider getCurrentProvider() => _currentProvider;

  /// Check if MapTiler is available
  static bool isMapTilerAvailable() =>
      _maptilerApiKey != null && _maptilerApiKey!.isNotEmpty;

  /// Check if Mapbox is available
  static bool isMapboxAvailable() =>
      _mapboxAccessToken != null && _mapboxAccessToken!.isNotEmpty;
}

