import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/obligation_service.dart';

class ObligationRepository {
  final ObligationService _s;
  ObligationRepository({required ObligationService service}) : _s = service;

  Future<Map<String, dynamic>> getObligationsSummary() =>
      _s.getObligationsSummary();
  Future<List<FinancialObligation>> getObligations() => _s.getObligations();
}
