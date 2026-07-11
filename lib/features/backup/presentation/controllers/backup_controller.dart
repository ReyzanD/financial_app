import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:financial_app/features/backup/domain/repositories/backup_repository_interface.dart';
import 'package:financial_app/services/logger_service.dart';

class BackupController extends ChangeNotifier {
  final BackupRepositoryInterface _r;
  BackupController({required BackupRepositoryInterface repository}) : _r = repository;

  List<File> _backups = [];
  bool _isLoading = false;
  bool _isCreating = false;

  List<File> get backups => _backups;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;

  Future<void> loadBackups() async {
    _isLoading = true; notifyListeners();
    try { _backups = List<File>.from(await _r.listBackups()); }
    catch (e) { LoggerService.error('Error loading backups', error: e); rethrow; }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> createBackup({bool share = false}) async {
    _isCreating = true; notifyListeners();
    try { await _r.performBackup(share: share); await loadBackups(); }
    catch (e) { LoggerService.error('Error creating backup', error: e); rethrow; }
    finally { _isCreating = false; notifyListeners(); }
  }

  Future<void> restoreBackup(String path) async {
    try { await _r.restoreBackup(path); }
    catch (e) { LoggerService.error('Error restoring backup', error: e); rethrow; }
  }

  Future<void> deleteBackup(String path) async {
    try { await _r.deleteBackup(path); await loadBackups(); }
    catch (e) { LoggerService.error('Error deleting backup', error: e); rethrow; }
  }

  Future<void> refresh() async => loadBackups();
}
