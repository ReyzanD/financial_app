import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/logger_service.dart';

/// Helper untuk state management optimizations dengan selective rebuilds
class StateManagementOptimizer {
  /// Create selective provider untuk avoid unnecessary rebuilds
  static Widget selectiveProvider<T>({
    required T Function(BuildContext) selector,
    required Widget Function(BuildContext, T) builder,
  }) {
    return Consumer<T>(
      builder: (context, value, child) {
        final selected = selector(context);
        return builder(context, selected);
      },
    );
  }

  /// Use context.select untuk selective rebuilds
  static R select<R>(BuildContext context, R Function(BuildContext) selector) {
    return context.select(selector);
  }

  /// Create provider composition
  static MultiProvider createProviderComposition({
    required List<ChangeNotifierProvider> providers,
    required Widget child,
  }) {
    return MultiProvider(
      providers: providers,
      child: child,
    );
  }

  /// Optimize rebuild dengan shouldRebuild callback
  static bool shouldRebuild<T>(T oldValue, T newValue, bool Function(T, T) compare) {
    return !compare(oldValue, newValue);
  }

  /// Log rebuild untuk debugging
  static void logRebuild(String widgetName, {Map<String, dynamic>? context}) {
    LoggerService.debug('Widget rebuilt: $widgetName', error: context);
  }
}

/// Extension untuk Provider optimizations
extension ProviderOptimizations on BuildContext {
  /// Select value dengan automatic optimization
  T selectValue<T>(T Function(BuildContext) selector) {
    return select(selector);
  }
}

