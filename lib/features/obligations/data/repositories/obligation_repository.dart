import 'package:financial_app/services/obligation_service.dart';
import 'package:financial_app/features/obligations/domain/repositories/obligation_repository_interface.dart';

class ObligationRepository implements ObligationRepositoryInterface {
  final ObligationService _s;
  ObligationRepository({required ObligationService service}) : _s = service;

  @override Future<Map<String, dynamic>> getObligationsSummary() => _s.getObligationsSummary();
  @override Future<List<dynamic>> getObligations() => _s.getObligations();
}
