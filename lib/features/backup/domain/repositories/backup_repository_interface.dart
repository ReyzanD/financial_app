import 'dart:io';

abstract class BackupRepositoryInterface {
  Future<List<dynamic>> listBackups();
  Future<File> performBackup({bool share = false});
  Future<void> restoreBackup(String path);
  Future<void> deleteBackup(String path);
}
