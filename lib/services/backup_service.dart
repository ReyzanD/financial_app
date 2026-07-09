import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/logger_service.dart';

class BackupService {
  final LocalDatabaseService _localDb = LocalDatabaseService();

  /// Create backup of all app data
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final db = await _localDb.database;

      // Fetch all data from local database
      final transactions = await db.query('transactions_232143');
      final categories = await db.query('categories_232143');
      final budgets = await db.query('budgets_232143');
      final goals = await db.query('financial_goals_232143');
      final obligations = await db.query('financial_obligations_232143');
      final receiptScans = await db.query('receipt_scans_232143');

      // New feature data
      final accounts = await db.query('accounts_232143');
      final debts = await db.query('debts_232143');
      final debtPayments = await db.query('debt_payments_232143');
      final subscriptions = await db.query('subscriptions_232143');
      final tags = await db.query('tags_232143');
      final transactionTags = await db.query('transaction_tags_232143');
      final expenseSplits = await db.query('expense_splits_232143');
      final challenges = await db.query('challenges_232143');
      final investments = await db.query('investments_232143');
      final templates = await db.query('transaction_templates_232143');
      final netWorthHistory = await db.query('net_worth_history_232143');
      final exchangeRates = await db.query('exchange_rates_232143');

      // Create backup object
      final backup = {
        'version': '2.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'transactions': transactions,
          'categories': categories,
          'budgets': budgets,
          'goals': goals,
          'obligations': obligations,
          'receipt_scans': receiptScans,
          'accounts': accounts,
          'debts': debts,
          'debt_payments': debtPayments,
          'subscriptions': subscriptions,
          'tags': tags,
          'transaction_tags': transactionTags,
          'expense_splits': expenseSplits,
          'challenges': challenges,
          'investments': investments,
          'templates': templates,
          'net_worth_history': netWorthHistory,
          'exchange_rates': exchangeRates,
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
        'obligationCount': (data['obligations'] as List?)?.length ?? 0,
        'accountCount': (data['accounts'] as List?)?.length ?? 0,
        'debtCount': (data['debts'] as List?)?.length ?? 0,
        'subscriptionCount': (data['subscriptions'] as List?)?.length ?? 0,
        'tagCount': (data['tags'] as List?)?.length ?? 0,
        'splitCount': (data['expense_splits'] as List?)?.length ?? 0,
        'challengeCount': (data['challenges'] as List?)?.length ?? 0,
        'investmentCount': (data['investments'] as List?)?.length ?? 0,
        'templateCount': (data['templates'] as List?)?.length ?? 0,
        'netWorthSnapshotCount':
            (data['net_worth_history'] as List?)?.length ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to read backup info: $e');
    }
  }

  /// Restore data from backup
  Future<void> restoreFromBackup(String filePath) async {
    try {
      final backup = await readBackupFromFile(filePath);

      if (!validateBackup(backup)) {
        throw Exception('Invalid backup file');
      }

      final data = backup['data'] as Map<String, dynamic>;
      final db = await _localDb.database;

      await db.transaction((txn) async {
        // Restore transactions
        final transactions = (data['transactions'] as List<dynamic>?) ?? [];
        for (var tx in transactions) {
          final txMap = tx as Map<String, dynamic>;
          await txn.insert(
            'transactions_232143',
            txMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore categories
        final categories = (data['categories'] as List<dynamic>?) ?? [];
        for (var cat in categories) {
          final catMap = cat as Map<String, dynamic>;
          await txn.insert(
            'categories_232143',
            catMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore budgets
        final budgets = (data['budgets'] as List<dynamic>?) ?? [];
        for (var budget in budgets) {
          final budgetMap = budget as Map<String, dynamic>;
          await txn.insert(
            'budgets_232143',
            budgetMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore goals
        final goals = (data['goals'] as List<dynamic>?) ?? [];
        for (var goal in goals) {
          final goalMap = goal as Map<String, dynamic>;
          await txn.insert(
            'financial_goals_232143',
            goalMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore obligations
        final obligations = (data['obligations'] as List<dynamic>?) ?? [];
        for (var obligation in obligations) {
          final obligationMap = obligation as Map<String, dynamic>;
          await txn.insert(
            'financial_obligations_232143',
            obligationMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore receipt scans
        final receiptScans = (data['receipt_scans'] as List<dynamic>?) ?? [];
        for (var scan in receiptScans) {
          final scanMap = scan as Map<String, dynamic>;
          await txn.insert(
            'receipt_scans_232143',
            scanMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore accounts
        final accounts = (data['accounts'] as List<dynamic>?) ?? [];
        for (var account in accounts) {
          final accountMap = account as Map<String, dynamic>;
          await txn.insert(
            'accounts_232143',
            accountMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore debts
        final debts = (data['debts'] as List<dynamic>?) ?? [];
        for (var debt in debts) {
          final debtMap = debt as Map<String, dynamic>;
          await txn.insert(
            'debts_232143',
            debtMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore debt payments
        final debtPayments = (data['debt_payments'] as List<dynamic>?) ?? [];
        for (var payment in debtPayments) {
          final paymentMap = payment as Map<String, dynamic>;
          await txn.insert(
            'debt_payments_232143',
            paymentMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore subscriptions
        final subscriptions = (data['subscriptions'] as List<dynamic>?) ?? [];
        for (var sub in subscriptions) {
          final subMap = sub as Map<String, dynamic>;
          await txn.insert(
            'subscriptions_232143',
            subMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore tags
        final tags = (data['tags'] as List<dynamic>?) ?? [];
        for (var tag in tags) {
          final tagMap = tag as Map<String, dynamic>;
          await txn.insert(
            'tags_232143',
            tagMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore transaction tags
        final transactionTags =
            (data['transaction_tags'] as List<dynamic>?) ?? [];
        for (var tt in transactionTags) {
          final ttMap = tt as Map<String, dynamic>;
          await txn.insert(
            'transaction_tags_232143',
            ttMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore expense splits
        final expenseSplits = (data['expense_splits'] as List<dynamic>?) ?? [];
        for (var split in expenseSplits) {
          final splitMap = split as Map<String, dynamic>;
          await txn.insert(
            'expense_splits_232143',
            splitMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore challenges
        final challenges = (data['challenges'] as List<dynamic>?) ?? [];
        for (var challenge in challenges) {
          final challengeMap = challenge as Map<String, dynamic>;
          await txn.insert(
            'challenges_232143',
            challengeMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore investments
        final investments = (data['investments'] as List<dynamic>?) ?? [];
        for (var investment in investments) {
          final investmentMap = investment as Map<String, dynamic>;
          await txn.insert(
            'investments_232143',
            investmentMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore templates
        final templates = (data['templates'] as List<dynamic>?) ?? [];
        for (var template in templates) {
          final templateMap = template as Map<String, dynamic>;
          await txn.insert(
            'transaction_templates_232143',
            templateMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore net worth history
        final netWorthHistory =
            (data['net_worth_history'] as List<dynamic>?) ?? [];
        for (var snapshot in netWorthHistory) {
          final snapshotMap = snapshot as Map<String, dynamic>;
          await txn.insert(
            'net_worth_history_232143',
            snapshotMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Restore exchange rates
        final exchangeRates = (data['exchange_rates'] as List<dynamic>?) ?? [];
        for (var rate in exchangeRates) {
          final rateMap = rate as Map<String, dynamic>;
          await txn.insert(
            'exchange_rates_232143',
            rateMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      LoggerService.info('✅ Backup restored successfully from $filePath');
    } catch (e) {
      LoggerService.error('Error restoring backup', error: e);
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
