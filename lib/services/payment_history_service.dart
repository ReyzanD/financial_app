import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Service untuk tracking payment history untuk obligations
class PaymentHistoryService {
  final ApiService _apiService = ApiService();

  /// Get payment history untuk obligation
  Future<List<Map<String, dynamic>>> getPaymentHistory(
    String obligationId,
  ) async {
    try {
      // Try to get payment history from API
      // If API doesn't have this endpoint, we'll use local storage
      final response = await _apiService.get(
        'obligations/$obligationId/payments',
      );
      return List<Map<String, dynamic>>.from(response['payments'] ?? []);
    } catch (e) {
      LoggerService.warning(
        'Payment history API not available, using local storage',
        error: e,
      );
      // Fallback to local storage if API doesn't support it
      return await _getLocalPaymentHistory(obligationId);
    }
  }

  /// Get local payment history (from SharedPreferences)
  Future<List<Map<String, dynamic>>> _getLocalPaymentHistory(
    String obligationId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('payment_history_$obligationId');
      if (historyJson != null) {
        // Parse JSON string to list
        final List<dynamic> historyList = jsonDecode(historyJson);
        return historyList.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error getting local payment history', error: e);
      return [];
    }
  }

  /// Record payment untuk obligation
  Future<void> recordPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      // Record in API
      await _apiService.recordObligationPayment(obligationId, paymentData);

      // Also save locally for history
      await _saveLocalPayment(obligationId, paymentData);

      LoggerService.success('Payment recorded successfully');
    } catch (e) {
      LoggerService.error('Error recording payment', error: e);
      // Still save locally even if API fails
      await _saveLocalPayment(obligationId, paymentData);
      rethrow;
    }
  }

  /// Save payment to local storage
  Future<void> _saveLocalPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await _getLocalPaymentHistory(obligationId);

      // Add new payment with timestamp
      history.add({
        ...paymentData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'recorded_at': DateTime.now().toIso8601String(),
      });

      // Save back to preferences
      final historyJson = jsonEncode(history);
      await prefs.setString('payment_history_$obligationId', historyJson);
    } catch (e) {
      LoggerService.error('Error saving local payment', error: e);
    }
  }

  /// Get payment statistics untuk obligation
  Future<Map<String, dynamic>> getPaymentStatistics(String obligationId) async {
    try {
      final history = await getPaymentHistory(obligationId);

      if (history.isEmpty) {
        return {
          'totalPayments': 0,
          'totalAmount': 0.0,
          'averageAmount': 0.0,
          'lastPaymentDate': null,
          'onTimePayments': 0,
          'latePayments': 0,
        };
      }

      double totalAmount = 0.0;
      int onTimePayments = 0;
      int latePayments = 0;
      DateTime? lastPaymentDate;

      for (var payment in history) {
        final amount = (payment['amount_paid'] as num?)?.toDouble() ?? 0.0;
        totalAmount += amount;

        final paymentDateStr = payment['payment_date']?.toString();
        if (paymentDateStr != null) {
          try {
            final paymentDate = DateTime.parse(paymentDateStr);
            if (lastPaymentDate == null ||
                paymentDate.isAfter(lastPaymentDate)) {
              lastPaymentDate = paymentDate;
            }
          } catch (e) {
            LoggerService.warning('Error parsing payment date', error: e);
          }
        }

        // Check if payment was on time (simplified - would need due date)
        final wasOnTime = payment['was_on_time'] as bool? ?? true;
        if (wasOnTime) {
          onTimePayments++;
        } else {
          latePayments++;
        }
      }

      return {
        'totalPayments': history.length,
        'totalAmount': totalAmount,
        'averageAmount':
            history.isNotEmpty ? totalAmount / history.length : 0.0,
        'lastPaymentDate': lastPaymentDate,
        'onTimePayments': onTimePayments,
        'latePayments': latePayments,
      };
    } catch (e) {
      LoggerService.error('Error getting payment statistics', error: e);
      return {
        'totalPayments': 0,
        'totalAmount': 0.0,
        'averageAmount': 0.0,
        'lastPaymentDate': null,
        'onTimePayments': 0,
        'latePayments': 0,
      };
    }
  }

  /// Delete payment from history
  Future<void> deletePayment(String obligationId, String paymentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await _getLocalPaymentHistory(obligationId);

      history.removeWhere((payment) => payment['id'] == paymentId);

      final historyJson = jsonEncode(history);
      await prefs.setString('payment_history_$obligationId', historyJson);

      LoggerService.success('Payment deleted from history');
    } catch (e) {
      LoggerService.error('Error deleting payment', error: e);
      rethrow;
    }
  }

  /// Get all payments across all obligations
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) => key.startsWith('payment_history_'),
      );

      final allPayments = <Map<String, dynamic>>[];
      for (var key in keys) {
        final obligationId = key.replaceFirst('payment_history_', '');
        final payments = await _getLocalPaymentHistory(obligationId);
        for (var payment in payments) {
          allPayments.add({...payment, 'obligation_id': obligationId});
        }
      }

      // Sort by date (newest first)
      allPayments.sort((a, b) {
        final dateA = a['recorded_at']?.toString() ?? '';
        final dateB = b['recorded_at']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });

      return allPayments;
    } catch (e) {
      LoggerService.error('Error getting all payments', error: e);
      return [];
    }
  }
}
