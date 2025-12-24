import 'package:financial_app/services/logger_service.dart';

/// Service untuk handle pagination pada data loading
class PaginationService<T> {
  final Future<List<T>> Function(int page, int limit) _fetchFunction;
  final int _pageSize;
  
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  List<T> _allItems = [];
  String? _error;

  PaginationService({
    required Future<List<T>> Function(int page, int limit) fetchFunction,
    int pageSize = 20,
  })  : _fetchFunction = fetchFunction,
        _pageSize = pageSize;

  /// Get current items
  List<T> get items => List.unmodifiable(_allItems);
  
  /// Check if has more pages
  bool get hasMore => _hasMore;
  
  /// Check if currently loading
  bool get isLoading => _isLoading;
  
  /// Get current page
  int get currentPage => _currentPage;
  
  /// Get error if any
  String? get error => _error;

  /// Load first page
  Future<List<T>> loadFirstPage() async {
    _currentPage = 1;
    _hasMore = true;
    _allItems = [];
    _error = null;
    return await loadNextPage();
  }

  /// Load next page
  Future<List<T>> loadNextPage() async {
    if (_isLoading || !_hasMore) {
      return _allItems;
    }

    _isLoading = true;
    _error = null;

    try {
      LoggerService.debug(
        '[PaginationService] Loading page $_currentPage (pageSize: $_pageSize)',
      );

      final newItems = await _fetchFunction(_currentPage, _pageSize);

      if (newItems.isEmpty) {
        _hasMore = false;
        LoggerService.debug('[PaginationService] No more items available');
      } else {
        _allItems.addAll(newItems);
        _currentPage++;
        
        // If returned items less than page size, no more pages
        if (newItems.length < _pageSize) {
          _hasMore = false;
        }

        LoggerService.success(
          '[PaginationService] Loaded ${newItems.length} items (total: ${_allItems.length})',
        );
      }

      return _allItems;
    } catch (e) {
      _error = e.toString();
      LoggerService.error('[PaginationService] Error loading page', error: e);
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Refresh all data
  Future<List<T>> refresh() async {
    return await loadFirstPage();
  }

  /// Clear all data
  void clear() {
    _allItems = [];
    _currentPage = 1;
    _hasMore = true;
    _error = null;
  }

  /// Add item to list (for optimistic updates)
  void addItem(T item) {
    _allItems.insert(0, item);
  }

  /// Update item in list
  void updateItem(int index, T item) {
    if (index >= 0 && index < _allItems.length) {
      _allItems[index] = item;
    }
  }

  /// Remove item from list
  void removeItem(int index) {
    if (index >= 0 && index < _allItems.length) {
      _allItems.removeAt(index);
    }
  }

  /// Get total count (if available)
  int get totalCount => _allItems.length;
}

