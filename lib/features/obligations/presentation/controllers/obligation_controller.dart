import 'package:flutter/material.dart';
import 'package:financial_app/features/obligations/domain/repositories/obligation_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/obligations/obligation_filters.dart';

class ObligationController extends ChangeNotifier {
  final ObligationRepositoryInterface _r;
  ObligationController({required ObligationRepositoryInterface repository}) : _r = repository {
    _searchController.addListener(() {
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
        final daysUntilDue = (obligation.daysUntilDue is num ? (obligation.daysUntilDue as num).toInt() : null) ?? 0;
        final dueDate = obligation.dueDate is DateTime ? obligation.dueDate as DateTime : (obligation.dueDate is String ? DateTime.tryParse(obligation.dueDate as String) : null) ?? now;
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
