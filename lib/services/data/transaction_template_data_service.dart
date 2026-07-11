import 'package:uuid/uuid.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';

/// Data service for Transaction Template CRUD operations.
class TransactionTemplateDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final TransactionDataService _transactionData;
  final _uuid = const Uuid();

  TransactionTemplateDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
    TransactionDataService? transactionData,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService(),
       _transactionData = transactionData ?? TransactionDataService();

  Future<String?> getCurrentUserId() async =>
      _authService.getCurrentUserId();

  Future<List<Map<String, dynamic>>> getTransactionTemplates() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final templates = await db.query(
        'transaction_templates_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
        orderBy: 'name_232143 ASC',
      );
      return List<Map<String, dynamic>>.from(templates);
    } catch (e) {
      LoggerService.error('Error getting transaction templates', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addTransactionTemplate(
    Map<String, dynamic> templateData,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final templateId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'template_id_232143': templateId,
        'user_id_232143': userId,
        'name_232143': templateData['name'],
        'amount_232143': templateData['amount'],
        'type_232143': templateData['type'],
        'category_id_232143': templateData['category_id'],
        'description_232143': templateData['description'],
        'payment_method_232143': templateData['payment_method'],
        'account_id_232143': templateData['account_id'],
        'is_recurring_232143': templateData['is_recurring'] == true ? 1 : 0,
        'recurrence_pattern_232143': templateData['recurrence_pattern'],
        'tags_232143': templateData['tags'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('transaction_templates_232143', data);
      LoggerService.info('✅ Template added: $templateId');
      return {'template': data};
    } catch (e) {
      LoggerService.error('Error adding template', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteTransactionTemplate(
    String templateId,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'transaction_templates_232143',
        where: 'template_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [templateId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Template deleted: $templateId');
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Template not found'};
      }
    } catch (e) {
      LoggerService.error('Error deleting template', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTransactionFromTemplate(
    String templateId,
  ) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final templates = await db.query(
        'transaction_templates_232143',
        where: 'template_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [templateId, userId],
        limit: 1,
      );

      if (templates.isEmpty) throw Exception('Template not found');

      final template = templates.first;
      final now = DateTime.now();

      final transactionData = {
        'amount': template['amount_232143'],
        'type': template['type_232143'],
        'category_id': template['category_id_232143'],
        'description': template['description_232143'],
        'payment_method': template['payment_method_232143'],
        'transaction_date': now.toIso8601String().split('T')[0],
        'transaction_time': now.toIso8601String().split('T')[1],
        'tags': template['tags_232143'],
      };

      return await _transactionData.addTransaction(transactionData);
    } catch (e) {
      LoggerService.error('Error creating transaction from template', error: e);
      rethrow;
    }
  }
}
