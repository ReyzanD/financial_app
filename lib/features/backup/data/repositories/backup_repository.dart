import 'dart:io';
import 'package:financial_app/services/backup_service.dart';
import 'package:financial_app/features/backup/domain/repositories/backup_repository_interface.dart';

class BackupRepository implements BackupRepositoryInterface {
  final BackupService _s;
  BackupRepository({BackupService? service}) : _s = service ?? BackupService();
  @override Future<List<dynamic>> listBackups() => _s.listBackups();
  @override Future<File> performBackup({bool share = false}) => _s.performBackup(share: share);
  @override Future<void> restoreBackup(String path) => _s.restoreFromBackup(path);
  @override Future<void> deleteBackup(String path) => _s.deleteBackup(path);
}
