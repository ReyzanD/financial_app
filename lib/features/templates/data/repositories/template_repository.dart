import 'package:financial_app/services/data/transaction_template_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/transaction_template_model.dart';

class TemplateRepository {
  final TransactionTemplateDataService _s;
  TemplateRepository({TransactionTemplateDataService? service})
    : _s = service ?? getIt<TransactionTemplateDataService>();
  Future<List<TransactionTemplateModel>> getTemplates() =>
      _s.getTransactionTemplates();
}
