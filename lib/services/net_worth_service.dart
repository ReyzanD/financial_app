import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/services/data/obligation_data_service.dart';
import 'package:financial_app/services/investment_service.dart';
import 'package:financial_app/services/data/net_worth_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class NetWorthService {
  final NetWorthDataService _netWorthData = getIt<NetWorthDataService>();
  final AccountService _accountService = getIt<AccountService>();
  final ObligationDataService _obligationData = getIt<ObligationDataService>();
  final InvestmentService _investmentService = getIt<InvestmentService>();

  Future<Map<String, dynamic>> calculateNetWorth() async {
    try {
      final totalAssets = await _calculateTotalAssets();
      final totalLiabilities = await _calculateTotalLiabilities();
      final netWorth = totalAssets - totalLiabilities;

      return {
        'net_worth': netWorth,
        'total_assets': totalAssets,
        'total_liabilities': totalLiabilities,
        'asset_breakdown': await _getAssetBreakdown(),
        'liability_breakdown': await _getLiabilityBreakdown(),
        'calculated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggerService.error('Error calculating net worth', error: e);
      rethrow;
    }
  }

  Future<double> _calculateTotalAssets() async {
    final accountBalance = await _accountService.getTotalBalance();
    final investmentValue = await _getTotalInvestmentValue();

    return accountBalance + investmentValue;
  }

  Future<double> _calculateTotalLiabilities() async {
    // Read debts from unified financial_obligations table
    final debts = await _obligationData.getObligations(type: 'debt');
    return debts.fold<double>(0, (sum, d) => sum + (d.currentBalance ?? d.monthlyAmount));
  }

  Future<Map<String, double>> _getAssetBreakdown() async {
    final accountsByType = await _accountService.getTotalBalanceByType();
    final investments = await _investmentService.getInvestments();

    final breakdown = Map<String, double>.from(accountsByType);
    breakdown['investments'] = investments.fold<double>(0, (sum, i) => sum + i.totalValue);

    return breakdown;
  }

  Future<Map<String, double>> _getLiabilityBreakdown() async {
    // Read debts from unified financial_obligations table
    final debts = await _obligationData.getObligations(type: 'debt');
    final breakdown = <String, double>{};

    for (var debt in debts) {
      final subtype = debt.debtType ?? debt.category ?? 'other';
      breakdown[subtype] = (breakdown[subtype] ?? 0) + (debt.currentBalance ?? debt.monthlyAmount);
    }

    return breakdown;
  }

  Future<double> _getTotalInvestmentValue() async {
    final investments = await _investmentService.getInvestments();
    return investments.fold<double>(0, (sum, i) => sum + i.totalValue);
  }

  Future<bool> recordSnapshot() async {
    try {
      final netWorth = await calculateNetWorth();
      final snapshot = {
        'snapshot_date': DateTime.now().toIso8601String().split('T')[0],
        'net_worth': netWorth['net_worth'],
        'total_assets': netWorth['total_assets'],
        'total_liabilities': netWorth['total_liabilities'],
        'asset_breakdown': netWorth['asset_breakdown'],
        'liability_breakdown': netWorth['liability_breakdown'],
      };

      await _netWorthData.recordNetWorthSnapshot(snapshot);
      LoggerService.success('Net worth snapshot recorded');
      return true;
    } catch (e) {
      LoggerService.error('Error recording net worth snapshot', error: e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHistory({int limit = 90}) async {
    try {
      return await _netWorthData.getNetWorthHistory(limit: limit);
    } catch (e) {
      LoggerService.error('Error getting net worth history', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNetWorthTrend() async {
    try {
      return await _netWorthData.getNetWorthTrend();
    } catch (e) {
      LoggerService.error('Error getting net worth trend', error: e);
      rethrow;
    }
  }
}
