import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/feature_models.dart';

class TransactionTemplateService {
  static const String _templatesKey = 'transaction_templates';

  Future<List<TransactionTemplateModel>> getTemplates({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString(_templatesKey);
      if (templatesJson == null) return [];

      final List<dynamic> decoded = jsonDecode(templatesJson);
      var templates =
          decoded
              .map(
                (e) => TransactionTemplateModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();

      templates.sort((a, b) => b.usageCount.compareTo(a.usageCount));

      if (limit != null && limit > 0) {
        templates = templates.take(limit).toList();
      }

      return templates;
    } catch (e) {
      LoggerService.error('Error getting templates', error: e);
      return [];
    }
  }

  Future<TransactionTemplateModel> createTemplate(
    TransactionTemplateModel template,
  ) async {
    try {
      final templates = await getTemplates();
      templates.add(template);
      await _saveTemplates(templates);
      LoggerService.success('Template created: ${template.name}');
      return template;
    } catch (e) {
      LoggerService.error('Error creating template', error: e);
      rethrow;
    }
  }

  Future<void> useTemplate(String templateId) async {
    try {
      final templates = await getTemplates();
      final index = templates.indexWhere((t) => t.id == templateId);
      if (index == -1) return;

      templates[index] = TransactionTemplateModel(
        id: templates[index].id,
        name: templates[index].name,
        amount: templates[index].amount,
        type: templates[index].type,
        categoryId: templates[index].categoryId,
        categoryName: templates[index].categoryName,
        description: templates[index].description,
        icon: templates[index].icon,
        color: templates[index].color,
        usageCount: templates[index].usageCount + 1,
        lastUsed: DateTime.now(),
        createdAt: templates[index].createdAt,
      );

      await _saveTemplates(templates);
    } catch (e) {
      LoggerService.error('Error using template', error: e);
    }
  }

  Future<TransactionTemplateModel> createFromTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final template = TransactionTemplateModel(
      id: 'template_${DateTime.now().millisecondsSinceEpoch}',
      name: transaction['category_name']?.toString() ?? 'Transaction',
      amount: (transaction['amount'] as num?)?.toDouble() ?? 0.0,
      type: transaction['type']?.toString() ?? 'expense',
      categoryId: transaction['category_id']?.toString(),
      categoryName: transaction['category_name']?.toString(),
      description: transaction['description']?.toString(),
      usageCount: 0,
      lastUsed: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return await createTemplate(template);
  }

  Future<void> deleteTemplate(String templateId) async {
    try {
      final templates = await getTemplates();
      templates.removeWhere((t) => t.id == templateId);
      await _saveTemplates(templates);
      LoggerService.success('Template deleted');
    } catch (e) {
      LoggerService.error('Error deleting template', error: e);
      rethrow;
    }
  }

  Map<String, dynamic> templateToTransactionData(
    TransactionTemplateModel template,
  ) {
    return {
      'amount': template.amount,
      'type': template.type,
      'category_id': template.categoryId,
      'category_name': template.categoryName,
      'description': template.description,
    };
  }

  Future<void> _saveTemplates(List<TransactionTemplateModel> templates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = templates.map((t) => t.toJson()).toList();
      await prefs.setString(_templatesKey, jsonEncode(jsonList));
    } catch (e) {
      LoggerService.error('Error saving templates', error: e);
      rethrow;
    }
  }
}
