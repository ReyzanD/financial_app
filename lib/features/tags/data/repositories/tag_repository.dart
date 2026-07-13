import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/transaction_tag_model.dart';
import 'package:financial_app/services/data/tag_data_service.dart';
import 'package:financial_app/features/tags/domain/repositories/tag_repository_interface.dart';

class TagRepository implements TagRepositoryInterface {
  final TagDataService _s;
  TagRepository() : _s = getIt<TagDataService>();
  @override
  Future<List<TransactionTagModel>> getTags() => _s.getTags();
}
