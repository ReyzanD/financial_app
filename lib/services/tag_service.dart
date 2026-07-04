import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/models/feature_models.dart';

class TagService {
  static const String _tagsKey = 'transaction_tags';
  static const String _transactionTagsKey = 'transaction_tag_mappings';

  Future<List<TransactionTagModel>> getTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tagsJson = prefs.getString(_tagsKey);
      if (tagsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(tagsJson);
      return decoded
          .map((e) => TransactionTagModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggerService.error('Error getting tags', error: e);
      return [];
    }
  }

  Future<TransactionTagModel> createTag(TransactionTagModel tag) async {
    try {
      final tags = await getTags();
      tags.add(tag);
      await _saveTags(tags);
      return tag;
    } catch (e) {
      LoggerService.error('Error creating tag', error: e);
      rethrow;
    }
  }

  Future<void> deleteTag(String tagId) async {
    try {
      final tags = await getTags();
      tags.removeWhere((t) => t.id == tagId);
      await _saveTags(tags);
    } catch (e) {
      LoggerService.error('Error deleting tag', error: e);
      rethrow;
    }
  }

  Future<void> addTagToTransaction(String transactionId, String tagId) async {
    try {
      final mappings = await _getTransactionTags(transactionId);
      if (!mappings.contains(tagId)) {
        mappings.add(tagId);
        await _saveTransactionTags(transactionId, mappings);
      }

      final tags = await getTags();
      final tagIndex = tags.indexWhere((t) => t.id == tagId);
      if (tagIndex != -1) {
        tags[tagIndex] = TransactionTagModel(
          id: tags[tagIndex].id,
          name: tags[tagIndex].name,
          color: tags[tagIndex].color,
          icon: tags[tagIndex].icon,
          usageCount: tags[tagIndex].usageCount + 1,
          createdAt: tags[tagIndex].createdAt,
        );
        await _saveTags(tags);
      }
    } catch (e) {
      LoggerService.error('Error adding tag to transaction', error: e);
    }
  }

  Future<void> removeTagFromTransaction(String transactionId, String tagId) async {
    try {
      final mappings = await _getTransactionTags(transactionId);
      mappings.remove(tagId);
      await _saveTransactionTags(transactionId, mappings);
    } catch (e) {
      LoggerService.error('Error removing tag from transaction', error: e);
    }
  }

  Future<List<String>> getTagsForTransaction(String transactionId) async {
    return await _getTransactionTags(transactionId);
  }

  Future<List<String>> getTransactionsByTag(String tagId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('${_transactionTagsKey}_'));
      final transactionIds = <String>[];

      for (var key in keys) {
        final mappingsJson = prefs.getString(key);
        if (mappingsJson != null) {
          final List<dynamic> decoded = jsonDecode(mappingsJson);
          final tagIds = decoded.map((e) => e.toString()).toList();
          if (tagIds.contains(tagId)) {
            transactionIds.add(key.replaceFirst('${_transactionTagsKey}_', ''));
          }
        }
      }

      return transactionIds;
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> searchTransactions({
    String? query,
    String? tagId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions_data');
      if (transactionsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(transactionsJson);
      final results = <String>[];

      for (var t in decoded) {
        final transaction = t as Map<String, dynamic>;
        bool matches = true;

        if (query != null && query.isNotEmpty) {
          final desc = (transaction['description']?.toString() ?? '').toLowerCase();
          final category = (transaction['category_name']?.toString() ?? '').toLowerCase();
          if (!desc.contains(query.toLowerCase()) && !category.contains(query.toLowerCase())) {
            matches = false;
          }
        }

        if (tagId != null) {
          final transactionId = transaction['id']?.toString() ?? '';
          final tags = await _getTransactionTags(transactionId);
          if (!tags.contains(tagId)) matches = false;
        }

        if (type != null) {
          final tType = transaction['type']?.toString() ?? '';
          if (tType != type) matches = false;
        }

        if (startDate != null) {
          final dateStr = transaction['transaction_date']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            final date = DateTime.parse(dateStr);
            if (date.isBefore(startDate)) matches = false;
          }
        }

        if (endDate != null) {
          final dateStr = transaction['transaction_date']?.toString() ?? '';
          if (dateStr.isNotEmpty) {
            final date = DateTime.parse(dateStr);
            if (date.isAfter(endDate)) matches = false;
          }
        }

        if (matches) {
          results.add(transaction['id']?.toString() ?? '');
        }
      }

      return results;
    } catch (e) {
      LoggerService.error('Error searching transactions', error: e);
      return [];
    }
  }

  Future<List<String>> _getTransactionTags(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_transactionTagsKey}_$transactionId';
      final tagsJson = prefs.getString(key);
      if (tagsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(tagsJson);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveTransactionTags(String transactionId, List<String> tagIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_transactionTagsKey}_$transactionId';
      await prefs.setString(key, jsonEncode(tagIds));
    } catch (e) {
      LoggerService.error('Error saving transaction tags', error: e);
    }
  }

  Future<void> _saveTags(List<TransactionTagModel> tags) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tags.map((t) => t.toJson()).toList();
      await prefs.setString(_tagsKey, jsonEncode(jsonList));
    } catch (e) {
      LoggerService.error('Error saving tags', error: e);
      rethrow;
    }
  }
}
