import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk performance monitoring dan analytics
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final Map<String, DateTime> _screenStartTimes = {};
  final Map<String, int> _apiResponseTimes = {};
  final List<Map<String, dynamic>> _performanceMetrics = [];
  Timer? _memoryMonitorTimer;

  /// Track screen load time
  void startScreenTracking(String screenName) {
    _screenStartTimes[screenName] = DateTime.now();
  }

  /// End screen tracking dan record metrics
  void endScreenTracking(String screenName) {
    final startTime = _screenStartTimes[screenName];
    if (startTime != null) {
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      _recordMetric('screen_load_time', {
        'screen': screenName,
        'load_time_ms': loadTime,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _screenStartTimes.remove(screenName);
      
      LoggerService.debug('Screen $screenName loaded in ${loadTime}ms');
    }
  }

  /// Track API response time
  void recordApiResponseTime(String endpoint, int responseTimeMs) {
    _apiResponseTimes[endpoint] = responseTimeMs;
    _recordMetric('api_response_time', {
      'endpoint': endpoint,
      'response_time_ms': responseTimeMs,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get average API response time untuk endpoint
  double getAverageApiResponseTime(String endpoint) {
    final times = _performanceMetrics
        .where((m) => 
            m['type'] == 'api_response_time' && 
            m['endpoint'] == endpoint)
        .map((m) => m['response_time_ms'] as int)
        .toList();
    
    if (times.isEmpty) return 0.0;
    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Record performance metric
  void _recordMetric(String type, Map<String, dynamic> data) {
    _performanceMetrics.add({
      'type': type,
      ...data,
    });
    
    // Keep only last 1000 metrics
    if (_performanceMetrics.length > 1000) {
      _performanceMetrics.removeAt(0);
    }
  }

  /// Start memory monitoring
  void startMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        _recordMemoryUsage();
      },
    );
  }

  /// Stop memory monitoring
  void stopMemoryMonitoring() {
    _memoryMonitorTimer?.cancel();
  }

  /// Record memory usage
  void _recordMemoryUsage() {
    if (kDebugMode) {
      // Get memory info (platform specific)
      // Note: Flutter doesn't have built-in memory monitoring
      // This is a placeholder for future implementation
      _recordMetric('memory_usage', {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
      });
    }
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final screenLoadTimes = _performanceMetrics
        .where((m) => m['type'] == 'screen_load_time')
        .map((m) => m['load_time_ms'] as int)
        .toList();
    
    final apiResponseTimes = _performanceMetrics
        .where((m) => m['type'] == 'api_response_time')
        .map((m) => m['response_time_ms'] as int)
        .toList();
    
    return {
      'total_metrics': _performanceMetrics.length,
      'screen_load_times': {
        'count': screenLoadTimes.length,
        'average_ms': screenLoadTimes.isEmpty 
            ? 0 
            : screenLoadTimes.reduce((a, b) => a + b) / screenLoadTimes.length,
        'min_ms': screenLoadTimes.isEmpty ? 0 : screenLoadTimes.reduce((a, b) => a < b ? a : b),
        'max_ms': screenLoadTimes.isEmpty ? 0 : screenLoadTimes.reduce((a, b) => a > b ? a : b),
      },
      'api_response_times': {
        'count': apiResponseTimes.length,
        'average_ms': apiResponseTimes.isEmpty 
            ? 0 
            : apiResponseTimes.reduce((a, b) => a + b) / apiResponseTimes.length,
        'min_ms': apiResponseTimes.isEmpty ? 0 : apiResponseTimes.reduce((a, b) => a < b ? a : b),
        'max_ms': apiResponseTimes.isEmpty ? 0 : apiResponseTimes.reduce((a, b) => a > b ? a : b),
      },
    };
  }

  /// Save performance metrics to storage
  Future<void> saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summary = getPerformanceSummary();
      await prefs.setString('performance_summary', summary.toString());
      LoggerService.info('Performance metrics saved');
    } catch (e) {
      LoggerService.error('Error saving performance metrics', error: e);
    }
  }

  /// Clear all metrics
  void clearMetrics() {
    _performanceMetrics.clear();
    _screenStartTimes.clear();
    _apiResponseTimes.clear();
    LoggerService.info('Performance metrics cleared');
  }

  /// Track app startup time
  void recordAppStartupTime(int startupTimeMs) {
    _recordMetric('app_startup_time', {
      'startup_time_ms': startupTimeMs,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track crash (placeholder untuk crash reporting)
  void recordCrash(String error, StackTrace? stackTrace) {
    _recordMetric('crash', {
      'error': error,
      'stack_trace': stackTrace?.toString() ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    });
    LoggerService.error('Crash recorded', error: error);
  }

  /// Track user session
  void startSession() {
    _recordMetric('session_start', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void endSession() {
    _recordMetric('session_end', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

