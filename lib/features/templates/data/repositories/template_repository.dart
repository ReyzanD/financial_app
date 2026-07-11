import 'package:financial_app/services/data/transaction_template_data_service.dart';
import 'package:financial_app/features/templates/domain/repositories/template_repository_interface.dart';

class TemplateRepository implements TemplateRepositoryInterface {
  final TransactionTemplateDataService _s;
  TemplateRepository({TransactionTemplateDataService? service}) : _s = service ?? TransactionTemplateDataService();
  @override Future<List<dynamic>> getTemplates() => _s.getTransactionTemplates();
}
