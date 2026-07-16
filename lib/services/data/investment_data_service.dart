import 'package:uuid/uuid.dart';
import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/services/local_database_service.dart';
import 'package:financial_app/services/local_auth_service.dart';
import 'package:financial_app/services/logger_service.dart';

/// Data service for Investment CRUD operations.
class InvestmentDataService {
  final LocalDatabaseService _dbService;
  final LocalAuthService _authService;
  final _uuid = const Uuid();

  InvestmentDataService({
    LocalDatabaseService? dbService,
    LocalAuthService? authService,
  }) : _dbService = dbService ?? LocalDatabaseService(),
       _authService = authService ?? LocalAuthService();

  Future<String?> getCurrentUserId() async => _authService.getCurrentUserId();

  Future<List<InvestmentModel>> getInvestments({String? type}) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      var where = 'user_id_232143 = ?';
      var whereArgs = <dynamic>[userId];

      if (type != null) {
        where += ' AND type_232143 = ?';
        whereArgs.add(type);
      }

      final investments = await db.query(
        'investments_232143',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at_232143 DESC',
      );
      return investments.map((m) => InvestmentModel.fromMap(m)).toList();
    } catch (e) {
      LoggerService.error('Error getting investments', error: e);
      rethrow;
    }
  }

  Future<InvestmentModel> addInvestment(Map<String, dynamic> invData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final invId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      final data = {
        'investment_id_232143': invId,
        'user_id_232143': userId,
        'name_232143': invData['name'],
        'type_232143': invData['type'] ?? 'other',
        'quantity_232143': invData['quantity'],
        'buy_price_232143': invData['buy_price'],
        'current_price_232143':
            invData['current_price'] ?? invData['buy_price'],
        'buy_date_232143': invData['buy_date'] ?? now.split('T')[0],
        'ticker_232143': invData['ticker'],
        'notes_232143': invData['notes'],
        'created_at_232143': now,
        'updated_at_232143': now,
      };

      await db.insert('investments_232143', data);
      LoggerService.info('✅ Investment added: $invId');
      return InvestmentModel.fromMap(data);
    } catch (e) {
      LoggerService.error('Error adding investment', error: e);
      rethrow;
    }
  }

  Future<void> updateInvestmentPrice(String invId, double newPrice) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      await db.update(
        'investments_232143',
        {
          'current_price_232143': newPrice,
          'updated_at_232143': DateTime.now().toIso8601String(),
        },
        where: 'investment_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [invId, userId],
      );

      LoggerService.info('✅ Investment price updated: $invId');
    } catch (e) {
      LoggerService.error('Error updating investment price', error: e);
      rethrow;
    }
  }

  Future<bool> deleteInvestment(String invId) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final rowsDeleted = await db.delete(
        'investments_232143',
        where: 'investment_id_232143 = ? AND user_id_232143 = ?',
        whereArgs: [invId, userId],
      );

      if (rowsDeleted > 0) {
        LoggerService.info('✅ Investment deleted: $invId');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error deleting investment', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPortfolioSummary() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) throw Exception('Not authenticated');

      final db = await _dbService.database;
      final investments = await db.query(
        'investments_232143',
        where: 'user_id_232143 = ?',
        whereArgs: [userId],
      );

      double totalValue = 0;
      double totalCost = 0;
      final byType = <String, dynamic>{};

      for (var inv in investments) {
        final quantity = (inv['quantity_232143'] as num?)?.toDouble() ?? 0.0;
        final buyPrice = (inv['buy_price_232143'] as num?)?.toDouble() ?? 0.0;
        final currentPrice =
            (inv['current_price_232143'] as num?)?.toDouble() ?? 0.0;
        final type = inv['type_232143'] as String? ?? 'other';

        final cost = quantity * buyPrice;
        final value = quantity * currentPrice;
        totalCost += cost;
        totalValue += value;

        byType[type] = {
          'value': (byType[type]?['value'] as double? ?? 0) + value,
          'cost': (byType[type]?['cost'] as double? ?? 0) + cost,
          'count': ((byType[type]?['count'] as int? ?? 0) + 1),
        };
      }

      final pnl = totalValue - totalCost;
      final pnlPercent = totalCost > 0 ? (pnl / totalCost) * 100 : 0;

      return {
        'total_value': totalValue,
        'total_cost': totalCost,
        'total_profit_loss': pnl,
        'total_profit_loss_percent': pnlPercent,
        'investment_count': investments.length,
        'by_type': byType,
      };
    } catch (e) {
      LoggerService.error('Error getting portfolio summary', error: e);
      rethrow;
    }
  }
}
