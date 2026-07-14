import 'dart:io';
import 'package:financial_app/services/backup_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class BackupRepository {
  final BackupService _s;
  BackupRepository({BackupService? service}) : _s = service ?? getIt<BackupService>();
  Future<List<dynamic>> listBackups() => _s.listBackups();
  Future<File> performBackup({bool share = false}) =>
      _s.performBackup(share: share);
  Future<void> restoreBackup(String path) => _s.restoreFromBackup(path);
  Future<void> deleteBackup(String path) => _s.deleteBackup(path);
}
