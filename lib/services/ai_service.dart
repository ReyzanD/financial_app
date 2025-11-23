import 'package:financial_app/services/api_service.dart';

class AIService {
  final ApiService _apiService = ApiService();

  /// Generate intelligent financial recommendations based on user data
  Future<Map<String, dynamic>> generateRecommendations() async {
    try {
      // Get backend AI recommendations if available
      final backendResponse = await _apiService.getAIRecommendations();

      // Handle different response formats from backend
      Map<String, dynamic>? backendRecs;

      if (backendResponse is Map<String, dynamic>) {
        backendRecs = backendResponse;
      } else if (backendResponse is List && backendResponse.isNotEmpty) {
        // If backend returns a list, take the first recommendation
        backendRecs = backendResponse[0] as Map<String, dynamic>;
      }

      if (backendRecs != null &&
          backendRecs.isNotEmpty &&
          backendRecs['recommendation'] != null) {
        return backendRecs;
      }
    } catch (e) {
      print('Backend AI not available, using local intelligence: $e');
    }

    // Fallback: Generate smart recommendations locally
    return await _generateLocalRecommendations();
  }

  /// Generate smart recommendations based on user's transaction patterns
  Future<Map<String, dynamic>> _generateLocalRecommendations() async {
    try {
      // Get user's recent data
      final transactions = await _apiService.getTransactions(limit: 100);
      final budgets = await _apiService.getBudgets();
      final goals = await _apiService.getGoals();

      // Analyze spending patterns
      final analysis = _analyzeSpendingPatterns(transactions);

      // Generate recommendation based on analysis
      final recommendation = _selectBestRecommendation(
        analysis,
        budgets,
        goals,
      );

      return recommendation;
    } catch (e) {
      print('Error generating local recommendations: $e');
      return _getDefaultRecommendation();
    }
  }

  Map<String, dynamic> _analyzeSpendingPatterns(List<dynamic> transactions) {
    double totalExpense = 0;
    double totalIncome = 0;
    Map<String, double> categorySpending = {};
    Map<String, int> categoryCount = {};

    // Current month transactions
    final now = DateTime.now();
    final thisMonthTransactions =
        transactions.where((t) {
          try {
            final date = DateTime.parse(t['date'] ?? '');
            return date.month == now.month && date.year == now.year;
          } catch (e) {
            return false;
          }
        }).toList();

    for (var transaction in thisMonthTransactions) {
      final amount = (transaction['amount'] ?? 0).toDouble();
      final type = transaction['type']?.toString().toLowerCase() ?? 'expense';
      final category = transaction['category_name']?.toString() ?? 'Lainnya';

      if (type == 'income') {
        totalIncome += amount;
      } else if (type == 'expense') {
        totalExpense += amount;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
    }

    // Find highest spending category
    String? highestCategory;
    double highestAmount = 0;
    categorySpending.forEach((category, amount) {
      if (amount > highestAmount) {
        highestAmount = amount;
        highestCategory = category;
      }
    });

    // Calculate savings rate
    final savingsRate =
        totalIncome > 0
            ? ((totalIncome - totalExpense) / totalIncome) * 100
            : 0;

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'savingsRate': savingsRate,
      'highestCategory': highestCategory,
      'highestAmount': highestAmount,
      'categorySpending': categorySpending,
      'categoryCount': categoryCount,
      'transactionCount': thisMonthTransactions.length,
    };
  }

  Map<String, dynamic> _selectBestRecommendation(
    Map<String, dynamic> analysis,
    List<dynamic> budgets,
    List<dynamic> goals,
  ) {
    final savingsRate = analysis['savingsRate'] as double;
    final totalExpense = analysis['totalExpense'] as double;
    final totalIncome = analysis['totalIncome'] as double;
    final highestCategory = analysis['highestCategory'] as String?;
    final highestAmount = analysis['highestAmount'] as double;

    // Priority 1: Low or negative savings rate
    if (savingsRate < 10) {
      return {
        'recommendation':
            '💡 Tingkatkan tabungan Anda! Saat ini Anda hanya menabung ${savingsRate.toStringAsFixed(1)}% dari pendapatan. Target ideal adalah 20-30% untuk kesehatan finansial yang baik.',
        'potential_savings': totalIncome * 0.2 - (totalIncome - totalExpense),
        'priority': 'high',
        'category': 'savings',
        'icon': 'flash',
      };
    }

    // Priority 2: High spending in one category
    if (highestCategory != null &&
        totalExpense > 0 &&
        (highestAmount / totalExpense) > 0.4) {
      final percentage = ((highestAmount / totalExpense) * 100).toStringAsFixed(
        0,
      );
      return {
        'recommendation':
            '📊 Pengeluaran "$highestCategory" Anda tinggi ($percentage% dari total). Coba kurangi 15% untuk menghemat Rp ${(highestAmount * 0.15).toInt()}/bulan.',
        'potential_savings': highestAmount * 0.15,
        'priority': 'medium',
        'category': highestCategory,
        'icon': 'warning_2',
      };
    }

    // Priority 3: No active goals
    if (goals.isEmpty) {
      return {
        'recommendation':
            '🎯 Buat target finansial! Orang dengan tujuan keuangan yang jelas 42% lebih berhasil mencapai stabilitas finansial. Mulai dengan goal kecil seperti dana darurat.',
        'potential_savings': 0,
        'priority': 'medium',
        'category': 'goals',
        'icon': 'medal',
      };
    }

    // Priority 4: Budget exceeded
    for (var budget in budgets) {
      final spent = (budget['spent'] ?? 0).toDouble();
      final limit = (budget['limit'] ?? 1).toDouble();
      if (spent > limit) {
        return {
          'recommendation':
              '⚠️ Budget "${budget['category_name']}" melebihi batas! Anda telah menghabiskan Rp ${spent.toInt()} dari budget Rp ${limit.toInt()}. Pertimbangkan untuk mengurangi pengeluaran kategori ini.',
          'potential_savings': spent - limit,
          'priority': 'high',
          'category': budget['category_name'],
          'icon': 'danger',
        };
      }
    }

    // Priority 5: Good savings rate - encourage
    if (savingsRate >= 20) {
      return {
        'recommendation':
            '🌟 Luar biasa! Tingkat tabungan Anda ${savingsRate.toStringAsFixed(0)}% sangat baik. Pertimbangkan untuk mengalokasikan lebih banyak ke investasi jangka panjang atau goal Anda.',
        'potential_savings': 0,
        'priority': 'low',
        'category': 'achievement',
        'icon': 'award',
      };
    }

    // Priority 6: Moderate savings - suggestions
    if (savingsRate >= 10 && savingsRate < 20) {
      return {
        'recommendation':
            '💪 Bagus! Tingkat tabungan ${savingsRate.toStringAsFixed(0)}% cukup solid. Coba tingkatkan 5% lagi dengan mengurangi pengeluaran tidak penting seperti langganan yang jarang dipakai.',
        'potential_savings': totalIncome * 0.05,
        'priority': 'low',
        'category': 'improvement',
        'icon': 'trend_up',
      };
    }

    // Default recommendation
    return _getDefaultRecommendation();
  }

  Map<String, dynamic> _getDefaultRecommendation() {
    return {
      'recommendation':
          '📈 Terus pantau keuangan Anda! Catat setiap transaksi untuk mendapat insight yang lebih baik tentang pola pengeluaran Anda.',
      'potential_savings': 0,
      'priority': 'low',
      'category': 'general',
      'icon': 'chart',
    };
  }

  /// Get spending insights for a specific period
  Future<Map<String, dynamic>> getSpendingInsights(String period) async {
    try {
      final transactions = await _apiService.getTransactions(limit: 200);
      final now = DateTime.now();

      List<dynamic> periodTransactions;

      switch (period) {
        case 'week':
          final weekAgo = now.subtract(const Duration(days: 7));
          periodTransactions =
              transactions.where((t) {
                try {
                  final date = DateTime.parse(t['date'] ?? '');
                  return date.isAfter(weekAgo);
                } catch (e) {
                  return false;
                }
              }).toList();
          break;
        case 'month':
          periodTransactions =
              transactions.where((t) {
                try {
                  final date = DateTime.parse(t['date'] ?? '');
                  return date.month == now.month && date.year == now.year;
                } catch (e) {
                  return false;
                }
              }).toList();
          break;
        default:
          periodTransactions = transactions;
      }

      return _analyzeSpendingPatterns(periodTransactions);
    } catch (e) {
      print('Error getting spending insights: $e');
      return {};
    }
  }

  /// Generate personalized tips based on spending patterns
  List<String> generateSmartTips(Map<String, dynamic> analysis) {
    final tips = <String>[];
    final savingsRate = analysis['savingsRate'] as double? ?? 0;
    final categorySpending =
        analysis['categorySpending'] as Map<String, double>? ?? {};

    // Tip 1: Savings rate based
    if (savingsRate < 10) {
      tips.add('Mulai dengan menabung 10% dari pendapatan setiap bulan');
    } else if (savingsRate < 20) {
      tips.add('Target menabung 20% untuk masa depan yang lebih aman');
    } else {
      tips.add('Alokasikan sebagian tabungan untuk investasi jangka panjang');
    }

    // Tip 2: Category specific
    if (categorySpending.containsKey('Makanan')) {
      tips.add('Coba meal prep untuk menghemat biaya makan hingga 30%');
    }
    if (categorySpending.containsKey('Transport')) {
      tips.add('Pertimbangkan transportasi umum untuk menghemat bensin');
    }
    if (categorySpending.containsKey('Hiburan')) {
      tips.add('Batasi entertainment budget di 5-10% dari pendapatan');
    }

    // Tip 3: General financial health
    tips.add('Review pengeluaran setiap akhir bulan untuk perbaikan');
    tips.add('Buat dana darurat minimal 3-6 bulan pengeluaran');

    return tips;
  }
}
