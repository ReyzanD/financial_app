import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/services/debt_service.dart';
import 'package:financial_app/services/investment_service.dart';
import 'package:financial_app/services/data/net_worth_data_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

class NetWorthService {
  final NetWorthDataService _netWorthData = getIt<NetWorthDataService>();
  final AccountService _accountService = getIt<AccountService>();
  final DebtService _debtService = getIt<DebtService>();
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
    return await _debtService.getTotalDebt();
  }

  Future<Map<String, double>> _getAssetBreakdown() async {
    final accountsByType = await _accountService.getTotalBalanceByType();
    final investments = await _investmentService.getInvestments();

    final breakdown = Map<String, double>.from(accountsByType);
    breakdown['investments'] = investments.fold<double>(
      0,
      (sum, i) => sum + i.totalValue,
    );

    return breakdown;
  }

  Future<Map<String, double>> _getLiabilityBreakdown() async {
    final debts = await _debtService.getDebts();
    final breakdown = <String, double>{};

    for (var debt in debts) {
      breakdown[debt.type] = (breakdown[debt.type] ?? 0) + debt.currentBalance;
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
