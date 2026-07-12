import 'package:financial_app/models/financial_obligation.dart';

abstract class ObligationRepositoryInterface {
  Future<Map<String, dynamic>> getObligationsSummary();
  Future<List<FinancialObligation>> getObligations();
}
