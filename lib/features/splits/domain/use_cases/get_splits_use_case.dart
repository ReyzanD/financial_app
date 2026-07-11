import 'package:financial_app/models/split_model.dart';
import 'package:financial_app/features/splits/domain/repositories/split_repository_interface.dart';
class GetSplitsUseCase { final SplitRepositoryInterface _r; GetSplitsUseCase(this._r); Future<List<SplitModel>> call({bool activeOnly = true}) => _r.getSplits(activeOnly: activeOnly); }
