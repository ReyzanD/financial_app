import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/cache_service.dart';

/// Helper untuk prefetching data untuk better perceived performance
class PrefetchHelper {
  static final CacheService _cacheService = CacheService();

  /// Prefetch data jika belum ada di cache
  static Future<void> prefetchIfNeeded<T>({
    required String cacheKey,
    required Future<T> Function() fetchFunction,
    int? cacheDuration,
  }) async {
    try {
      // Check if data already in cache
      final cached = await _cacheService.get<T>(cacheKey, cacheDuration: cacheDuration);
      if (cached != null) {
        LoggerService.debug('[PrefetchHelper] Data already cached: $cacheKey');
        return;
      }

      // Prefetch in background
      LoggerService.debug('[PrefetchHelper] Prefetching: $cacheKey');
      final data = await fetchFunction();
      await _cacheService.set(cacheKey, data, cacheDuration: cacheDuration);
      LoggerService.success('[PrefetchHelper] Prefetched and cached: $cacheKey');
    } catch (e) {
      LoggerService.error('[PrefetchHelper] Error prefetching $cacheKey', error: e);
      // Don't throw - prefetch failures shouldn't block UI
    }
  }

  /// Prefetch multiple items in parallel
  static Future<void> prefetchMultiple(List<PrefetchTask> tasks) async {
    try {
      final futures = tasks.map((task) => prefetchIfNeeded(
        cacheKey: task.cacheKey,
        fetchFunction: task.fetchFunction,
        cacheDuration: task.cacheDuration,
      )).toList();

      await Future.wait(futures);
      LoggerService.success('[PrefetchHelper] Prefetched ${tasks.length} items');
    } catch (e) {
      LoggerService.error('[PrefetchHelper] Error prefetching multiple items', error: e);
    }
  }

  /// Prefetch next page data (for pagination)
  static Future<void> prefetchNextPage<T>({
    required String baseCacheKey,
    required int currentPage,
    required Future<List<T>> Function(int page) fetchFunction,
    int? cacheDuration,
  }) async {
    try {
      final nextPage = currentPage + 1;
      final cacheKey = '$baseCacheKey:page:$nextPage';
      
      await prefetchIfNeeded(
        cacheKey: cacheKey,
        fetchFunction: () => fetchFunction(nextPage),
        cacheDuration: cacheDuration,
      );
    } catch (e) {
      LoggerService.error('[PrefetchHelper] Error prefetching next page', error: e);
    }
  }
}

/// Task definition untuk prefetch
class PrefetchTask<T> {
  final String cacheKey;
  final Future<T> Function() fetchFunction;
  final int? cacheDuration;

  PrefetchTask({
    required this.cacheKey,
    required this.fetchFunction,
    this.cacheDuration,
  });
}

