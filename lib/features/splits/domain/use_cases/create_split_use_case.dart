import 'package:financial_app/models/split_model.dart';
import 'package:financial_app/features/splits/domain/repositories/split_repository_interface.dart';

class CreateSplitUseCase {
  final SplitRepositoryInterface _r;
  CreateSplitUseCase(this._r);
  Future<SplitModel> call(SplitModel split) => _r.createSplit(split);
}
