import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk monitor network connectivity
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  final List<Function(bool)> _listeners = [];

  /// Get current connectivity status
  bool get isOnline => _isOnline;

  /// Stream untuk listen connectivity changes
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((results) => results.any((result) => result != ConnectivityResult.none))
      .distinct();

  /// Initialize network monitoring
  Future<void> initialize() async {
    try {
      // Check initial status
      final results = await _connectivity.checkConnectivity();
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      LoggerService.info('Network status: ${_isOnline ? "Online" : "Offline"}');

      // Listen to connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final wasOnline = _isOnline;
          _isOnline = results.any((result) => result != ConnectivityResult.none);
          
          if (wasOnline != _isOnline) {
            LoggerService.info(
              'Network status changed: ${_isOnline ? "Online" : "Offline"}',
            );
            _notifyListeners();
          }
        },
        onError: (error) {
          LoggerService.error('Connectivity error', error: error);
        },
      );
    } catch (e) {
      LoggerService.error('Failed to initialize network service', error: e);
      // Assume online if we can't check
      _isOnline = true;
    }
  }

  /// Check connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      return _isOnline;
    } catch (e) {
      LoggerService.error('Failed to check connectivity', error: e);
      return true; // Assume online on error
    }
  }

  /// Add listener for connectivity changes
  void addListener(Function(bool) listener) {
    _listeners.add(listener);
  }

  /// Remove listener
  void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      try {
        listener(_isOnline);
      } catch (e) {
        LoggerService.error('Error in connectivity listener', error: e);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _listeners.clear();
  }
}

