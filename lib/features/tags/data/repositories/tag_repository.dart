import 'package:financial_app/services/data/tag_data_service.dart';
import 'package:financial_app/features/tags/domain/repositories/tag_repository_interface.dart';

class TagRepository implements TagRepositoryInterface {
  final TagDataService _s;
  TagRepository({TagDataService? service}) : _s = service ?? TagDataService();
  @override Future<List<dynamic>> getTags() => _s.getTags();
}
