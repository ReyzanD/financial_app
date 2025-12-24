import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk transaction templates
class TransactionTemplatesService {
  static const String _templatesKey = 'transaction_templates';

  /// Save template
  Future<void> saveTemplate({
    required String name,
    required String type,
    required double amount,
    required String categoryId,
    String? description,
    String? locationName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString(_templatesKey);
      
      List<Map<String, dynamic>> templates = [];
      if (templatesJson != null) {
        final decoded = json.decode(templatesJson) as List;
        templates = decoded.cast<Map<String, dynamic>>();
      }
      
      templates.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'description': description,
        'location_name': locationName,
        'created_at': DateTime.now().toIso8601String(),
        'usage_count': 0,
      });
      
      await prefs.setString(_templatesKey, json.encode(templates));
      LoggerService.debug('Saved transaction template: $name');
    } catch (e) {
      LoggerService.error('Error saving template', error: e);
    }
  }

  /// Get all templates
  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString(_templatesKey);
      
      if (templatesJson == null) return [];
      
      final decoded = json.decode(templatesJson) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      LoggerService.error('Error getting templates', error: e);
      return [];
    }
  }

  /// Get templates by type
  Future<List<Map<String, dynamic>>> getTemplatesByType(String type) async {
    final templates = await getTemplates();
    return templates.where((t) => t['type'] == type).toList();
  }

  /// Increment template usage
  Future<void> incrementUsage(String templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString(_templatesKey);
      
      if (templatesJson == null) return;
      
      final templates = (json.decode(templatesJson) as List).cast<Map<String, dynamic>>();
      final index = templates.indexWhere((t) => t['id'] == templateId);
      
      if (index != -1) {
        templates[index]['usage_count'] = ((templates[index]['usage_count'] as num?)?.toInt() ?? 0) + 1;
        await prefs.setString(_templatesKey, json.encode(templates));
      }
    } catch (e) {
      LoggerService.error('Error incrementing template usage', error: e);
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString(_templatesKey);
      
      if (templatesJson == null) return;
      
      final templates = (json.decode(templatesJson) as List).cast<Map<String, dynamic>>();
      templates.removeWhere((t) => t['id'] == templateId);
      
      await prefs.setString(_templatesKey, json.encode(templates));
      LoggerService.debug('Deleted template: $templateId');
    } catch (e) {
      LoggerService.error('Error deleting template', error: e);
    }
  }

  /// Get most used templates
  Future<List<Map<String, dynamic>>> getMostUsedTemplates({int limit = 5}) async {
    final templates = await getTemplates();
    templates.sort((a, b) {
      final countA = (a['usage_count'] as num?)?.toInt() ?? 0;
      final countB = (b['usage_count'] as num?)?.toInt() ?? 0;
      return countB.compareTo(countA);
    });
    return templates.take(limit).toList();
  }
}

