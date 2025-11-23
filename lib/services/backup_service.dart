import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:financial_app/services/api_service.dart';

class BackupService {
  final ApiService _apiService = ApiService();

  /// Create backup of all app data
  Future<Map<String, dynamic>> createBackup() async {
    try {
      // Fetch all data from API
      final transactions = await _apiService.getTransactions(limit: 10000);
      final categories = await _apiService.getCategories();
      final budgets = await _apiService.getBudgets();
      final goals = await _apiService.getGoals();

      // Create backup object
      final backup = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'transactions': transactions,
          'categories': categories,
          'budgets': budgets,
          'goals': goals,
        },
      };

      return backup;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  /// Save backup to file
  Future<File> saveBackupToFile(Map<String, dynamic> backup) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'financial_app_backup_$timestamp.json';
      final file = File('${directory.path}/$filename');

      final jsonString = JsonEncoder.withIndent('  ').convert(backup);
      await file.writeAsString(jsonString);

      return file;
    } catch (e) {
      throw Exception('Failed to save backup file: $e');
    }
  }

  /// Share backup file
  Future<void> shareBackup(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Financial App Backup',
        text: 'Backup file dari Financial App',
      );
    } catch (e) {
      throw Exception('Failed to share backup: $e');
    }
  }

  /// Complete backup process (create, save, and optionally share)
  Future<File> performBackup({bool share = false}) async {
    final backup = await createBackup();
    final file = await saveBackupToFile(backup);

    if (share) {
      await shareBackup(file);
    }

    return file;
  }

  /// Read backup from file
  Future<Map<String, dynamic>> readBackupFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Backup file not found');
      }

      final jsonString = await file.readAsString();
      final backup = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (backup['version'] == null || backup['data'] == null) {
        throw Exception('Invalid backup file format');
      }

      return backup;
    } catch (e) {
      throw Exception('Failed to read backup file: $e');
    }
  }

  /// Validate backup data
  bool validateBackup(Map<String, dynamic> backup) {
    try {
      // Check required fields
      if (backup['version'] == null) return false;
      if (backup['timestamp'] == null) return false;
      if (backup['data'] == null) return false;

      final data = backup['data'] as Map<String, dynamic>;

      // Check data structure (not content)
      if (data['transactions'] == null) return false;
      if (data['categories'] == null) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get backup information without restoring
  Future<Map<String, dynamic>> getBackupInfo(String filePath) async {
    try {
      final backup = await readBackupFromFile(filePath);
      final data = backup['data'] as Map<String, dynamic>;

      return {
        'version': backup['version'],
        'timestamp': backup['timestamp'],
        'transactionCount': (data['transactions'] as List?)?.length ?? 0,
        'categoryCount': (data['categories'] as List?)?.length ?? 0,
        'budgetCount': (data['budgets'] as List?)?.length ?? 0,
        'goalCount': (data['goals'] as List?)?.length ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to read backup info: $e');
    }
  }

  /// Restore data from backup (Note: This requires backend support)
  /// In a real implementation, this would sync with the backend
  Future<void> restoreFromBackup(String filePath) async {
    try {
      final backup = await readBackupFromFile(filePath);

      if (!validateBackup(backup)) {
        throw Exception('Invalid backup file');
      }

      // In a real app, you would:
      // 1. Upload backup data to backend
      // 2. Backend validates and merges/replaces data
      // 3. Re-sync app with backend

      // For now, we'll throw an informative message
      throw UnimplementedError(
        'Restore requires backend support. '
        'Please implement backend endpoint to restore data.',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// List available backups in app directory
  Future<List<File>> listBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files =
          directory
              .listSync()
              .where(
                (item) =>
                    item is File &&
                    item.path.endsWith('.json') &&
                    item.path.contains('financial_app_backup'),
              )
              .map((item) => item as File)
              .toList();

      // Sort by modification date (newest first)
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      return files;
    } catch (e) {
      throw Exception('Failed to list backups: $e');
    }
  }

  /// Delete a backup file
  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  /// Get backup file size
  Future<String> getBackupSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();

      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
