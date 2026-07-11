import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/cache_service.dart';

void main() {
  late CacheService cacheService;

  setUp(() {
    // Initialize SharedPreferences with empty values for each test
    SharedPreferences.setMockInitialValues({});
    cacheService = CacheService();
  });

  tearDown(() async {
    // Clean up cache between tests
    await cacheService.clearAll();
  });

  group('CacheService', () {
    test('get should return null for missing key', () async {
      final result = await cacheService.get<String>('missing_key');
      expect(result, isNull);
    });

    test('set and get should return stored value', () async {
      await cacheService.set<String>('test_key', 'test_value');
      final result = await cacheService.get<String>('test_key');
      expect(result, 'test_value');
    });

    test('set and get should work with integer values', () async {
      await cacheService.set<int>('int_key', 42);
      final result = await cacheService.get<int>('int_key');
      expect(result, 42);
    });

    test('set and get should work with double values', () async {
      await cacheService.set<double>('double_key', 3.14);
      final result = await cacheService.get<double>('double_key');
      expect(result, closeTo(3.14, 0.001));
    });

    test('set and get should work with list values', () async {
      final list = ['a', 'b', 'c'];
      await cacheService.set<List<String>>('list_key', list);
      final result = await cacheService.get<List<String>>('list_key');
      expect(result, list);
    });

    test('set and get should work with map values', () async {
      final map = {'name': 'test', 'value': 123};
      await cacheService.set<Map<String, dynamic>>('map_key', map);
      final result = await cacheService.get<Map<String, dynamic>>('map_key');
      expect(result, map);
    });

    test('get should return cached value from memory on second call', () async {
      await cacheService.set<String>('mem_key', 'memory_value');
      // First call loads into memory
      await cacheService.get<String>('mem_key');
      // Second call should hit memory cache
      final result = await cacheService.get<String>('mem_key');
      expect(result, 'memory_value');
    });

    test('remove should delete cached value', () async {
      await cacheService.set<String>('remove_key', 'to_be_removed');
      await cacheService.remove('remove_key');
      final result = await cacheService.get<String>('remove_key');
      expect(result, isNull);
    });

    test('clearAll should remove all cached values', () async {
      await cacheService.set<String>('key1', 'value1');
      await cacheService.set<String>('key2', 'value2');
      await cacheService.set<String>('key3', 'value3');

      await cacheService.clearAll();

      expect(await cacheService.get<String>('key1'), isNull);
      expect(await cacheService.get<String>('key2'), isNull);
      expect(await cacheService.get<String>('key3'), isNull);
    });

    test('get should return cached data for valid duration', () async {
      await cacheService.set<String>('valid_key', 'valid_value');
      // Use a generous cache duration so data is still valid
      final result =
          await cacheService.get<String>('valid_key', cacheDuration: 3600);
      expect(result, 'valid_value');
    });

    test('getStats should return cache statistics', () async {
      await cacheService.set<String>('stat_key', 'stat_value');
      final stats = await cacheService.getStats();

      expect(stats, containsPair('memoryCacheSize', 1));
      expect(stats, containsPair('maxMemoryCacheSize', 50));
      expect(stats['diskCacheSize'], isA<int>());
      expect(stats['totalSize'], isA<int>());
    });

    test('invalidatePattern should remove keys matching pattern', () async {
      await cacheService.set<String>('user_1_data', 'user1');
      await cacheService.set<String>('user_2_data', 'user2');
      await cacheService.set<String>('settings_1', 'settings');

      await cacheService.invalidatePattern('user_');

      expect(await cacheService.get<String>('user_1_data'), isNull);
      expect(await cacheService.get<String>('user_2_data'), isNull);
      expect(await cacheService.get<String>('settings_1'), 'settings');
    });

    test('should handle concurrent set and get operations', () async {
      await Future.wait([
        cacheService.set<String>('concurrent_1', 'value1'),
        cacheService.set<String>('concurrent_2', 'value2'),
        cacheService.set<String>('concurrent_3', 'value3'),
      ]);

      final results = await Future.wait([
        cacheService.get<String>('concurrent_1'),
        cacheService.get<String>('concurrent_2'),
        cacheService.get<String>('concurrent_3'),
      ]);

      expect(results[0], 'value1');
      expect(results[1], 'value2');
      expect(results[2], 'value3');
    });
  });
}
