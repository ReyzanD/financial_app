import 'package:financial_app/features/splits/domain/repositories/split_repository_interface.dart';
class DeleteSplitUseCase { final SplitRepositoryInterface _r; DeleteSplitUseCase(this._r); Future<void> call(String id) => _r.deleteSplit(id); }
