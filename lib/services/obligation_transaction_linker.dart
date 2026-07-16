import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/models/financial_obligation.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/payment_history_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Service untuk menghubungkan obligations dengan transactions
class ObligationTransactionLinker {
  final ObligationDataService _obligationData = getIt<ObligationDataService>();
  final TransactionDataService _transactionData =
      getIt<TransactionDataService>();
  final PaymentHistoryService _paymentService = getIt<PaymentHistoryService>();

  /// Auto-link transaction to obligation berdasarkan amount dan date
  Future<String?> autoLinkTransaction(
    String transactionId,
    Map<String, dynamic> transaction,
  ) async {
    try {
      final transactionAmount =
          (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final transactionDate =
          transaction['date'] != null
              ? DateTime.parse(transaction['date'].toString())
              : DateTime.now();

      // Get all obligations
      final obligations = await _obligationData.getObligations();

      // Find matching obligation
      for (var obligation in obligations) {
        final monthlyAmount = obligation.monthlyAmount;

        // Match by amount (within 5% tolerance) and date (within 7 days)
        final amountMatch =
            (transactionAmount - monthlyAmount).abs() / monthlyAmount < 0.05;
        final dateMatch = _isDateNearDueDate(transactionDate, obligation);

        if (amountMatch && dateMatch) {
          // Link transaction to obligation
          await linkTransactionToObligation(
            obligation.id,
            transactionId,
            transaction,
          );

          LoggerService.success(
            'Auto-linked transaction to ${obligation.name}',
          );

          return obligation.id;
        }
      }

      return null;
    } catch (e) {
      LoggerService.error('Error auto-linking transaction', error: e);
      return null;
    }
  }

  /// Check if transaction date is near obligation due date
  bool _isDateNearDueDate(
    DateTime transactionDate,
    FinancialObligation obligation,
  ) {
    try {
      final dueDayOfMonth = obligation.dueDate.day;
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, dueDayOfMonth);

      // Check if transaction is within 7 days of due date
      final daysDifference = (transactionDate.difference(dueDate)).inDays.abs();
      return daysDifference <= 7;
    } catch (e) {
      return false;
    }
  }

  /// Manually link transaction to obligation
  Future<void> linkTransactionToObligation(
    String obligationId,
    String transactionId,
    Map<String, dynamic> transaction,
  ) async {
    try {
      // Save link in local storage
      final prefs = await SharedPreferences.getInstance();
      final linksJson = prefs.getString('obligation_transaction_links') ?? '{}';
      final links = jsonDecode(linksJson) as Map<String, dynamic>;

      // Store link: obligation_id -> [transaction_ids]
      if (!links.containsKey(obligationId)) {
        links[obligationId] = [];
      }

      final transactionIds = List<String>.from(links[obligationId] as List);
      if (!transactionIds.contains(transactionId)) {
        transactionIds.add(transactionId);
        links[obligationId] = transactionIds;
      }

      // Also store reverse link: transaction_id -> obligation_id
      final reverseLinksJson =
          prefs.getString('transaction_obligation_links') ?? '{}';
      final reverseLinks = jsonDecode(reverseLinksJson) as Map<String, dynamic>;
      reverseLinks[transactionId] = obligationId;

      await prefs.setString('obligation_transaction_links', jsonEncode(links));
      await prefs.setString(
        'transaction_obligation_links',
        jsonEncode(reverseLinks),
      );

      // If transaction amount matches obligation amount, record as payment
      final transactionAmount =
          (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      final obligations = await _obligationData.getObligations();
      final obligation = obligations.firstWhere(
        (o) => o.id == obligationId,
        orElse:
            () => FinancialObligation(
              id: '',
              name: '',
              monthlyAmount: 0.0,
              dueDate: DateTime.now(),
              type: ObligationType.bill,
              daysUntilDue: 0,
            ),
      );

      if (obligation.id.isNotEmpty) {
        final monthlyAmount = obligation.monthlyAmount;
        if ((transactionAmount - monthlyAmount).abs() / monthlyAmount < 0.1) {
          // Amount matches, record as payment
          await _paymentService.recordPayment(obligationId, {
            'amount_paid': transactionAmount,
            'payment_date':
                transaction['date']?.toString() ??
                DateTime.now().toIso8601String(),
            'payment_method':
                transaction['payment_method']?.toString() ?? 'manual',
            'transaction_id': transactionId,
            'was_on_time': true, // Could be calculated based on due date
          });
        }
      }

      LoggerService.success('Transaction linked to obligation');
    } catch (e) {
      LoggerService.error('Error linking transaction to obligation', error: e);
      rethrow;
    }
  }

  /// Get linked transactions for obligation
  Future<List<String>> getLinkedTransactions(String obligationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final linksJson = prefs.getString('obligation_transaction_links') ?? '{}';
      final links = jsonDecode(linksJson) as Map<String, dynamic>;

      if (links.containsKey(obligationId)) {
        return List<String>.from(links[obligationId] as List);
      }

      return [];
    } catch (e) {
      LoggerService.error('Error getting linked transactions', error: e);
      return [];
    }
  }

  /// Get obligation for transaction
  Future<String?> getObligationForTransaction(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reverseLinksJson =
          prefs.getString('transaction_obligation_links') ?? '{}';
      final reverseLinks = jsonDecode(reverseLinksJson) as Map<String, dynamic>;

      return reverseLinks[transactionId]?.toString();
    } catch (e) {
      LoggerService.error('Error getting obligation for transaction', error: e);
      return null;
    }
  }

  /// Unlink transaction from obligation
  Future<void> unlinkTransaction(
    String obligationId,
    String transactionId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove from obligation -> transactions map
      final linksJson = prefs.getString('obligation_transaction_links') ?? '{}';
      final links = jsonDecode(linksJson) as Map<String, dynamic>;

      if (links.containsKey(obligationId)) {
        final transactionIds = List<String>.from(links[obligationId] as List);
        transactionIds.remove(transactionId);
        links[obligationId] = transactionIds;
        await prefs.setString(
          'obligation_transaction_links',
          jsonEncode(links),
        );
      }

      // Remove from transaction -> obligation map
      final reverseLinksJson =
          prefs.getString('transaction_obligation_links') ?? '{}';
      final reverseLinks = jsonDecode(reverseLinksJson) as Map<String, dynamic>;
      reverseLinks.remove(transactionId);
      await prefs.setString(
        'transaction_obligation_links',
        jsonEncode(reverseLinks),
      );

      LoggerService.success('Transaction unlinked from obligation');
    } catch (e) {
      LoggerService.error('Error unlinking transaction', error: e);
      rethrow;
    }
  }

  /// Auto-create transaction when bill is marked as paid
  Future<String?> createTransactionFromPayment(
    String obligationId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final obligations = await _obligationData.getObligations();
      final obligation = obligations.firstWhere(
        (o) => o.id == obligationId,
        orElse:
            () => FinancialObligation(
              id: '',
              name: '',
              monthlyAmount: 0.0,
              dueDate: DateTime.now(),
              type: ObligationType.bill,
              daysUntilDue: 0,
            ),
      );

      if (obligation.id.isEmpty) {
        LoggerService.warning('Obligation not found for payment');
        return null;
      }

      // Create transaction data
      final transactionData = {
        'amount': paymentData['amount_paid'] ?? obligation.monthlyAmount,
        'type': 'expense',
        'category_id': _getCategoryIdForObligation(obligation),
        'description': '${obligation.name} - ${obligation.type.name}',
        'payment_method': paymentData['payment_method'] ?? 'manual',
        'transaction_date':
            paymentData['payment_date'] ??
            DateTime.now().toIso8601String().split('T')[0],
        'time': DateTime.now().toString().split(' ')[1].substring(0, 5),
      };

      // Create transaction via data service
      final transactionModel = await _transactionData.addTransaction(
        transactionData,
      );
      final transactionId = transactionModel.id;

      // Link transaction to obligation
      await linkTransactionToObligation(
        obligationId,
        transactionId,
        transactionData,
      );

      return transactionId;
    } catch (e) {
      LoggerService.error('Error creating transaction from payment', error: e);
      return null;
    }
  }

  /// Get category ID for obligation (helper method)
  String? _getCategoryIdForObligation(FinancialObligation obligation) {
    return null;
  }

  /// Check for duplicate transactions
  Future<bool> isDuplicateTransaction(
    String obligationId,
    double amount,
    DateTime paymentDate,
  ) async {
    try {
      final paymentHistory = await _paymentService.getPaymentHistory(
        obligationId,
      );

      for (var payment in paymentHistory) {
        final paymentAmount =
            (payment['amount_paid'] as num?)?.toDouble() ?? 0.0;
        final paymentDateStr = payment['payment_date']?.toString();

        if (paymentDateStr != null) {
          try {
            final paymentDateTime = DateTime.parse(paymentDateStr);
            final amountMatch =
                (paymentAmount - amount).abs() < 1000; // Within 1000 rupiah
            final dateMatch =
                paymentDateTime.year == paymentDate.year &&
                paymentDateTime.month == paymentDate.month &&
                paymentDateTime.day == paymentDate.day;

            if (amountMatch && dateMatch) {
              return true;
            }
          } catch (e) {
            LoggerService.warning('Error parsing payment date', error: e);
          }
        }
      }

      return false;
    } catch (e) {
      LoggerService.error('Error checking duplicate transaction', error: e);
      return false;
    }
  }
}
