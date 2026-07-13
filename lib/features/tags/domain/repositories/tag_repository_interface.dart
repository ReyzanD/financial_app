import 'package:financial_app/models/transaction_tag_model.dart';

abstract class TagRepositoryInterface {
  Future<List<TransactionTagModel>> getTags();
}
