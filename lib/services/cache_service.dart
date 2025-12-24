import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk enhanced caching strategies
/// Multi-layer caching dengan memory, disk, dan network layers
class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const String _cacheVersionPrefix = 'cache_version_';
  static const int _defaultCacheDuration = 3600; // 1 hour in seconds

  // In-memory cache
  final Map<String, CacheItem> _memoryCache = {};
  static const int _maxMemoryCacheSize = 50; // Max items in memory

  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// Get cached data
  /// Returns cached data if available and not expired, null otherwise
  Future<T?> get<T>(String key, {int? cacheDuration}) async {
    try {
      // Check memory cache first
      if (_memoryCache.containsKey(key)) {
        final item = _memoryCache[key]!;
        if (!item.isExpired(cacheDuration ?? _defaultCacheDuration)) {
          LoggerService.debug('[CacheService] Cache hit (memory): $key');
          return item.data as T?;
        } else {
          _memoryCache.remove(key);
        }
      }

      // Check disk cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_cachePrefix$key');
      final timestamp = prefs.getInt('$_cacheTimestampPrefix$key');

      if (cachedData != null && timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final duration = (cacheDuration ?? _defaultCacheDuration) * 1000;

        if (age < duration) {
          // Cache is valid
          final data = jsonDecode(cachedData) as T;
          
          // Store in memory cache
          _addToMemoryCache(key, data);
          
          LoggerService.debug('[CacheService] Cache hit (disk): $key');
          return data;
        } else {
          // Cache expired, remove it
          await _remove(key);
          LoggerService.debug('[CacheService] Cache expired: $key');
        }
      }

      LoggerService.debug('[CacheService] Cache miss: $key');
      return null;
    } catch (e) {
      LoggerService.error('[CacheService] Error getting cache', error: e);
      return null;
    }
  }

  /// Set cached data
  Future<void> set<T>(String key, T data, {int? cacheDuration}) async {
    try {
      // Store in memory cache
      _addToMemoryCache(key, data);

      // Store in disk cache
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString('$_cachePrefix$key', jsonData);
      await prefs.setInt('$_cacheTimestampPrefix$key', timestamp);

      LoggerService.debug('[CacheService] Cache set: $key');
    } catch (e) {
      LoggerService.error('[CacheService] Error setting cache', error: e);
    }
  }

  /// Remove cached data
  Future<void> remove(String key) async {
    await _remove(key);
  }

  Future<void> _remove(String key) async {
    try {
      // Remove from memory
      _memoryCache.remove(key);

      // Remove from disk
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
      await prefs.remove('$_cacheTimestampPrefix$key');
      await prefs.remove('$_cacheVersionPrefix$key');

      LoggerService.debug('[CacheService] Cache removed: $key');
    } catch (e) {
      LoggerService.error('[CacheService] Error removing cache', error: e);
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    try {
      // Clear memory cache
      _memoryCache.clear();

      // Clear disk cache
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_cachePrefix) || 
        key.startsWith(_cacheTimestampPrefix) ||
        key.startsWith(_cacheVersionPrefix)
      ).toList();

      for (final key in cacheKeys) {
        await prefs.remove(key);
      }

      LoggerService.info('[CacheService] All cache cleared');
    } catch (e) {
      LoggerService.error('[CacheService] Error clearing cache', error: e);
    }
  }

  /// Clear expired cache
  Future<void> clearExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix)).toList();

      for (final key in cacheKeys) {
        final cacheKey = key.substring(_cachePrefix.length);
        final timestamp = prefs.getInt('$_cacheTimestampPrefix$cacheKey');

        if (timestamp != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          final duration = _defaultCacheDuration * 1000;

          if (age >= duration) {
            await _remove(cacheKey);
          }
        }
      }

      LoggerService.debug('[CacheService] Expired cache cleared');
    } catch (e) {
      LoggerService.error('[CacheService] Error clearing expired cache', error: e);
    }
  }

  /// Add to memory cache with size limit
  void _addToMemoryCache(String key, dynamic data) {
    // Remove oldest items if cache is full
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[key] = CacheItem(data, DateTime.now());
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix)).toList();

      int totalSize = 0;
      int expiredCount = 0;

      for (final key in cacheKeys) {
        final cacheKey = key.substring(_cachePrefix.length);
        final timestamp = prefs.getInt('$_cacheTimestampPrefix$cacheKey');
        final data = prefs.getString(key);

        if (data != null) {
          totalSize += data.length;
        }

        if (timestamp != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          final duration = _defaultCacheDuration * 1000;
          if (age >= duration) {
            expiredCount++;
          }
        }
      }

      return {
        'memoryCacheSize': _memoryCache.length,
        'diskCacheSize': cacheKeys.length,
        'totalSize': totalSize,
        'expiredCount': expiredCount,
        'maxMemoryCacheSize': _maxMemoryCacheSize,
      };
    } catch (e) {
      LoggerService.error('[CacheService] Error getting stats', error: e);
      return {};
    }
  }

  /// Invalidate cache by pattern
  Future<void> invalidatePattern(String pattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_cachePrefix) && 
        key.contains(pattern)
      ).toList();

      for (final key in cacheKeys) {
        final cacheKey = key.substring(_cachePrefix.length);
        await _remove(cacheKey);
      }

      LoggerService.debug('[CacheService] Cache invalidated for pattern: $pattern');
    } catch (e) {
      LoggerService.error('[CacheService] Error invalidating pattern', error: e);
    }
  }
}

/// Cache item for memory cache
class CacheItem {
  final dynamic data;
  final DateTime timestamp;

  CacheItem(this.data, this.timestamp);

  bool isExpired(int durationSeconds) {
    final age = DateTime.now().difference(timestamp).inSeconds;
    return age >= durationSeconds;
  }
}

