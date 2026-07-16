import 'dart:async';
import 'package:financial_app/services/financial_calendar_service.dart';

/// Calendar Repository - delegates to FinancialCalendarService.
class CalendarRepository {
  final FinancialCalendarService _service;

  CalendarRepository({FinancialCalendarService? service})
      : _service = service ?? FinancialCalendarService();

  Future<List<Map<String, dynamic>>> getMonthEvents(int year, int month) async {
    return await _service.getMonthEvents(year, month);
  }
}
