import 'dart:async';
import 'package:flutter/material.dart';
import 'package:financial_app/features/obligations/data/repositories/obligation_repository.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/obligations/obligation_filters.dart';

class ObligationController extends ChangeNotifier {
  final ObligationRepository _r;
  Timer? _debounceTimer;

  ObligationController({required ObligationRepository repository}) : _r = repository {
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = _searchController.text;
      notifyListeners();
    });
  }

  String _selectedView = 'all';
  int _refreshKey = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic> _summary = {};
  bool _summaryLoading = false;
  String? _summaryError;
  ObligationFilters _filters = ObligationFilters();

  String get selectedView => _selectedView;
  int get refreshKey => _refreshKey;
  TextEditingController get searchController => _searchController;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get summary => _summary;
  bool get summaryLoading => _summaryLoading;
  String? get summaryError => _summaryError;
  ObligationFilters get filters => _filters;

  Future<void> applyFilters(ObligationFilters filters) async {
    _filters = filters;
    await refresh();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void setView(String view) {
    _selectedView = view;
    notifyListeners();
  }

  Future<void> refresh() async {
    _refreshKey++;
    notifyListeners();
    await loadSummary();
  }

  Future<void> loadSummary() async {
    _summaryLoading = true;
    _summaryError = null;
    notifyListeners();
    try {
      final summary = await _r.getObligationsSummary();
      final obligations = await _r.getObligations();

      final now = DateTime.now();
      final endOfWeek = now.add(Duration(days: 7 - now.weekday));

      int dueThisWeek = 0;
      int overdue = 0;

      for (var obligation in obligations) {
        final daysUntilDue = obligation.daysUntilDue;
        final dueDate = obligation.dueDate;
        if (daysUntilDue < 0) {
          overdue++;
        } else if (dueDate.isBefore(endOfWeek) || dueDate.isAtSameMomentAs(endOfWeek)) {
          dueThisWeek++;
        }
      }

      _summary = {...summary, 'dueThisWeek': dueThisWeek, 'overdue': overdue};
    } catch (e) {
      LoggerService.error('Error loading obligations summary', error: e);
      _summaryError = e.toString();
      _summary = {'monthlyTotal': 0.0, 'totalDebt': 0.0, 'dueThisWeek': 0, 'overdue': 0};
    } finally {
      _summaryLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchController.clear();
  }
}
