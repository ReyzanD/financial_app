import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/transaction_tag_model.dart';
import 'package:financial_app/services/data/tag_data_service.dart';

class TagRepository {
  final TagDataService _s;
  TagRepository() : _s = getIt<TagDataService>();
  Future<List<TransactionTagModel>> getTags() => _s.getTags();
}
