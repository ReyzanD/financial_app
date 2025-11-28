import 'base_api.dart';

/// API client for obligation-related endpoints
class ObligationApi {
  /// Get all obligations
  static Future<List<dynamic>> getObligations({String? type}) async {
    String endpoint = 'obligations';
    if (type != null) endpoint += '?type=$type';
    final response = await BaseApiClient.get(endpoint);
    return response['obligations'] ?? [];
  }

  /// Get upcoming obligations
  static Future<List<dynamic>> getUpcomingObligations({int days = 7}) async {
    final endpoint = 'obligations/upcoming?days=$days';
    final response = await BaseApiClient.get(endpoint);
    return response['obligations'] ?? [];
  }

  /// Get obligations summary
  static Future<Map<String, dynamic>> getObligationsSummary() async {
    final obligations = await getObligations();

    double monthlyTotal = 0.0;
    double totalDebt = 0.0;

    for (var obligation in obligations) {
      final monthlyAmountRaw = obligation['monthly_amount_232143'];
      final monthlyAmount =
          monthlyAmountRaw is num
              ? monthlyAmountRaw.toDouble()
              : (double.tryParse(monthlyAmountRaw?.toString() ?? '0') ?? 0.0);
      monthlyTotal += monthlyAmount;

      if (obligation['type_232143'] == 'debt') {
        final currentBalanceRaw = obligation['current_balance_232143'];
        final currentBalance =
            currentBalanceRaw is num
                ? currentBalanceRaw.toDouble()
                : (double.tryParse(currentBalanceRaw?.toString() ?? '0') ??
                    0.0);
        totalDebt += currentBalance;
      }
    }

    return {
      'monthlyTotal': monthlyTotal,
      'totalDebt': totalDebt,
      'obligationsCount': obligations.length,
    };
  }

  /// Create new obligation
  static Future<Map<String, dynamic>> createObligation(
    Map<String, dynamic> obligationData,
  ) async {
    return await BaseApiClient.post('obligations', obligationData);
  }

  /// Update obligation
  static Future<Map<String, dynamic>> updateObligation(
    String id,
    Map<String, dynamic> obligationData,
  ) async {
    return await BaseApiClient.put('obligations/$id', obligationData);
  }

  /// Delete obligation
  static Future<Map<String, dynamic>> deleteObligation(String id) async {
    return await BaseApiClient.delete('obligations/$id');
  }

  /// Record obligation payment
  static Future<Map<String, dynamic>> recordObligationPayment(
    String id,
    Map<String, dynamic> paymentData,
  ) async {
    return await BaseApiClient.post('obligations/$id/payments', paymentData);
  }
}
