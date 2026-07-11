import 'package:flutter/foundation.dart';
import 'package:financial_app/services/financial_calendar_service.dart';
import 'package:financial_app/services/logger_service.dart';

class CalendarController extends ChangeNotifier {
  final FinancialCalendarService _s;
  CalendarController({required FinancialCalendarService service}) : _s = service;

  bool _isLoading = false; String? _error;
  List<Map<String, dynamic>> _events = [];
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime _selectedDay = DateTime.now();

  bool get isLoading => _isLoading; String? get error => _error;
  List<Map<String, dynamic>> get events => _events;
  int get selectedYear => _selectedYear; int get selectedMonth => _selectedMonth; DateTime get selectedDay => _selectedDay;

  void setDate(int year, int month, DateTime day) {
    _selectedYear = year; _selectedMonth = month; _selectedDay = day; notifyListeners();
    loadMonthEvents();
  }

  Future<void> loadMonthEvents() async {
    _isLoading = true; _error = null; notifyListeners();
    try { _events = await _s.getMonthEvents(_selectedYear, _selectedMonth); }
    catch (e) { LoggerService.error('Error loading month events', error: e); _error = e.toString(); }
    finally { _isLoading = false; notifyListeners(); }
  }
}
