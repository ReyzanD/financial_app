import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk mengelola bill templates
class BillTemplateService {
  /// Get predefined templates
  List<Map<String, dynamic>> getPredefinedTemplates() {
    return [
      {
        'id': 'pln',
        'name': 'PLN (Listrik)',
        'category': 'utility',
        'type': 'bill',
        'icon': '⚡',
        'description': 'Tagihan listrik bulanan',
        'default_due_date': 20,
      },
      {
        'id': 'pdam',
        'name': 'PDAM (Air)',
        'category': 'utility',
        'type': 'bill',
        'icon': '💧',
        'description': 'Tagihan air bulanan',
        'default_due_date': 15,
      },
      {
        'id': 'internet',
        'name': 'Internet',
        'category': 'internet',
        'type': 'bill',
        'icon': '🌐',
        'description': 'Tagihan internet bulanan',
        'default_due_date': 1,
      },
      {
        'id': 'phone',
        'name': 'Telepon',
        'category': 'phone',
        'type': 'bill',
        'icon': '📱',
        'description': 'Tagihan telepon bulanan',
        'default_due_date': 10,
      },
      {
        'id': 'insurance',
        'name': 'Asuransi',
        'category': 'insurance',
        'type': 'bill',
        'icon': '🛡️',
        'description': 'Premi asuransi bulanan',
        'default_due_date': 5,
      },
      {
        'id': 'netflix',
        'name': 'Netflix',
        'category': 'subscription',
        'type': 'subscription',
        'icon': '🎬',
        'description': 'Langganan Netflix',
        'default_due_date': 1,
        'subscription_cycle': 'monthly',
      },
      {
        'id': 'spotify',
        'name': 'Spotify',
        'category': 'subscription',
        'type': 'subscription',
        'icon': '🎵',
        'description': 'Langganan Spotify',
        'default_due_date': 1,
        'subscription_cycle': 'monthly',
      },
      {
        'id': 'youtube',
        'name': 'YouTube Premium',
        'category': 'subscription',
        'type': 'subscription',
        'icon': '📺',
        'description': 'Langganan YouTube Premium',
        'default_due_date': 1,
        'subscription_cycle': 'monthly',
      },
      {
        'id': 'credit_card',
        'name': 'Kartu Kredit',
        'category': 'credit_card',
        'type': 'debt',
        'icon': '💳',
        'description': 'Tagihan kartu kredit',
        'default_due_date': 25,
      },
      {
        'id': 'mortgage',
        'name': 'Kredit Rumah',
        'category': 'mortgage',
        'type': 'debt',
        'icon': '🏠',
        'description': 'Angsuran kredit rumah',
        'default_due_date': 1,
      },
    ];
  }

  /// Get templates by category
  List<Map<String, dynamic>> getTemplatesByCategory(String category) {
    return getPredefinedTemplates()
        .where((template) => template['category'] == category)
        .toList();
  }

  /// Get custom templates (saved by user)
  Future<List<Map<String, dynamic>>> getCustomTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString('custom_bill_templates');
      if (templatesJson != null) {
        final List<dynamic> templatesList = jsonDecode(templatesJson);
        return templatesList.map((t) => t as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error getting custom templates', error: e);
      return [];
    }
  }

  /// Save custom template
  Future<void> saveCustomTemplate(Map<String, dynamic> template) async {
    try {
      final customTemplates = await getCustomTemplates();
      
      // Check if template with same ID exists
      final existingIndex = customTemplates.indexWhere(
        (t) => t['id'] == template['id'],
      );
      
      if (existingIndex >= 0) {
        customTemplates[existingIndex] = template;
      } else {
        customTemplates.add(template);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = jsonEncode(customTemplates);
      await prefs.setString('custom_bill_templates', templatesJson);
      
      LoggerService.success('Custom template saved');
    } catch (e) {
      LoggerService.error('Error saving custom template', error: e);
      rethrow;
    }
  }

  /// Delete custom template
  Future<void> deleteCustomTemplate(String templateId) async {
    try {
      final customTemplates = await getCustomTemplates();
      customTemplates.removeWhere((t) => t['id'] == templateId);
      
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = jsonEncode(customTemplates);
      await prefs.setString('custom_bill_templates', templatesJson);
      
      LoggerService.success('Custom template deleted');
    } catch (e) {
      LoggerService.error('Error deleting custom template', error: e);
      rethrow;
    }
  }

  /// Get all templates (predefined + custom)
  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final predefined = getPredefinedTemplates();
    final custom = await getCustomTemplates();
    return [...predefined, ...custom];
  }

  /// Get template by ID
  Future<Map<String, dynamic>?> getTemplateById(String templateId) async {
    final allTemplates = await getAllTemplates();
    try {
      return allTemplates.firstWhere((t) => t['id'] == templateId);
    } catch (e) {
      return null;
    }
  }

  /// Convert template to obligation data
  Map<String, dynamic> templateToObligationData(
    Map<String, dynamic> template, {
    double? amount,
  }) {
    return {
      'name_232143': template['name'],
      'type_232143': template['type'] ?? 'bill',
      'category_232143': template['category'] ?? 'other',
      'due_date_232143': template['default_due_date'] ?? 1,
      'monthly_amount_232143': amount ?? 0.0,
      if (template['subscription_cycle'] != null)
        'subscription_cycle_232143': template['subscription_cycle'],
      if (template['type'] == 'subscription')
        'is_subscription_232143': true,
    };
  }
}

