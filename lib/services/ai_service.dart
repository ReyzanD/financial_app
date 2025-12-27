import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/expense_predictor.dart';
import 'package:financial_app/services/spending_pattern_analyzer.dart';
import 'package:financial_app/services/recommendation_personalizer.dart';

class AIService {
  final ApiService _apiService = ApiService();
  final ExpensePredictor _expensePredictor = ExpensePredictor();
  final SpendingPatternAnalyzer _patternAnalyzer = SpendingPatternAnalyzer();
  final RecommendationPersonalizer _personalizer = RecommendationPersonalizer();

  /// Generate multiple intelligent financial recommendations (3-5)
  Future<List<Map<String, dynamic>>> generateMultipleRecommendations({
    int limit = 5,
  }) async {
    try {
      // Get user's recent data
      final transactionsData = await _apiService.getTransactions(limit: 500);
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
      final budgets = await _apiService.getBudgets();
      final goals = await _apiService.getGoals();

      // Enhanced multi-period analysis
      final multiPeriodAnalysis = _patternAnalyzer.analyzeMultiPeriod(
        transactions: transactions,
        monthsToAnalyze: 3,
      );

      // Current month analysis
      final currentAnalysis = _analyzeSpendingPatterns(transactions);

      // Merge analyses
      final enhancedAnalysis = {
        ...currentAnalysis,
        'multi_period': multiPeriodAnalysis,
        'trends': multiPeriodAnalysis['trends'] ?? {},
        'category_correlations':
            multiPeriodAnalysis['category_correlations'] ?? {},
        'day_of_week_patterns':
            multiPeriodAnalysis['day_of_week_patterns'] ?? {},
        'frequent_merchants': multiPeriodAnalysis['frequent_merchants'] ?? [],
      };

      // Generate all recommendations
      final allRecommendations = <Map<String, dynamic>>[];

      // Get base recommendations using the same logic as _selectBestRecommendation
      // but collecting all recommendations instead of just the best
      final baseRecs = _collectAllRecommendations(
        enhancedAnalysis,
        budgets,
        goals,
      );
      allRecommendations.addAll(baseRecs);

      // Add contextual recommendations
      final contextualRecs = await _generateContextualRecommendations(
        enhancedAnalysis,
        budgets,
        goals,
      );
      allRecommendations.addAll(contextualRecs);

      // Personalize and sort
      final personalizedRecs = await _personalizer.personalizeRecommendations(
        allRecommendations,
      );

      // Return top N recommendations
      return personalizedRecs.take(limit).toList();
    } catch (e) {
      LoggerService.error(
        'Error generating multiple recommendations',
        error: e,
      );
      return [];
    }
  }

  /// Generate intelligent financial recommendations based on user data (single, for backward compatibility)
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
        final firstItem = backendResponse[0];
        if (firstItem is Map) {
          backendRecs = Map<String, dynamic>.from(
            firstItem.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      }

      if (backendRecs != null &&
          backendRecs.isNotEmpty &&
          backendRecs['recommendation'] != null) {
        return backendRecs;
      }
    } catch (e) {
      LoggerService.warning(
        'Backend AI not available, using local intelligence',
        error: e,
      );
    }

    // Fallback: Generate smart recommendations locally
    return await _generateLocalRecommendations();
  }

  /// Generate smart recommendations based on user's transaction patterns
  Future<Map<String, dynamic>> _generateLocalRecommendations() async {
    try {
      // Get user's recent data - increased limit for multi-period analysis
      final transactionsData = await _apiService.getTransactions(limit: 500);
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
      final budgets = await _apiService.getBudgets();
      final goals = await _apiService.getGoals();

      // Enhanced multi-period analysis
      final multiPeriodAnalysis = _patternAnalyzer.analyzeMultiPeriod(
        transactions: transactions,
        monthsToAnalyze: 3,
      );

      // Current month analysis (for backward compatibility)
      final currentAnalysis = _analyzeSpendingPatterns(transactions);

      // Merge analyses
      final enhancedAnalysis = {
        ...currentAnalysis,
        'multi_period': multiPeriodAnalysis,
        'trends': multiPeriodAnalysis['trends'] ?? {},
        'category_correlations':
            multiPeriodAnalysis['category_correlations'] ?? {},
        'day_of_week_patterns':
            multiPeriodAnalysis['day_of_week_patterns'] ?? {},
        'frequent_merchants': multiPeriodAnalysis['frequent_merchants'] ?? [],
      };

      // Generate recommendations based on enhanced analysis
      final recommendations = _selectBestRecommendation(
        enhancedAnalysis,
        budgets,
        goals,
      );

      // Add contextual recommendations (time-sensitive, event-based)
      final contextualRecs = await _generateContextualRecommendations(
        enhancedAnalysis,
        budgets,
        goals,
      );

      // Combine and personalize
      final allRecommendations = [recommendations, ...contextualRecs];
      final personalizedRecs = await _personalizer.personalizeRecommendations(
        allRecommendations,
      );

      // Return top recommendation
      return personalizedRecs.isNotEmpty
          ? personalizedRecs.first
          : recommendations;
    } catch (e) {
      LoggerService.error('Error generating local recommendations', error: e);
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

  /// Collect all recommendations (not just the best one)
  List<Map<String, dynamic>> _collectAllRecommendations(
    Map<String, dynamic> analysis,
    List<dynamic> budgets,
    List<dynamic> goals,
  ) {
    // Use the same logic as _selectBestRecommendation but return all recommendations
    final allRecs = <Map<String, dynamic>>[];
    final savingsRate = (analysis['savingsRate'] as num?)?.toDouble() ?? 0.0;
    final totalExpense = (analysis['totalExpense'] as num?)?.toDouble() ?? 0.0;
    final totalIncome = (analysis['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final highestCategory = analysis['highestCategory'] as String?;
    final highestAmount =
        (analysis['highestAmount'] as num?)?.toDouble() ?? 0.0;
    final transactionCount = analysis['transactionCount'] as int? ?? 0;

    // Enhanced analysis data
    final trendsRaw = analysis['trends'];
    final trends =
        trendsRaw is Map
            ? Map<String, dynamic>.from(
              trendsRaw.map((key, value) => MapEntry(key.toString(), value)),
            )
            : <String, dynamic>{};
    final dayOfWeekPatternsRaw = analysis['day_of_week_patterns'];
    final dayOfWeekPatterns =
        dayOfWeekPatternsRaw is Map
            ? Map<String, dynamic>.from(
              dayOfWeekPatternsRaw.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
            : <String, dynamic>{};

    // Add all the recommendation logic here (same as _selectBestRecommendation)
    // Recommendation 1: Low savings rate
    if (savingsRate < 10) {
      final potentialSavings = totalIncome * 0.2 - (totalIncome - totalExpense);
      final confidence = _calculateConfidence(
        dataQuality: transactionCount > 10 ? 0.9 : 0.6,
        patternStrength: (10 - savingsRate) / 10,
        urgency: 1.0,
      );
      final impact = _calculateImpactScore(
        potentialSavings: potentialSavings,
        totalIncome: totalIncome,
      );
      final actionability = _calculateActionabilityScore(
        action: 'review_budget',
        category: 'savings',
      );
      final score = _calculateRecommendationScore(
        confidence: confidence,
        impact: impact,
        actionability: actionability,
        relevance: 1.0,
        timing: _getTemporalRelevance(),
      );
      allRecs.add({
        'recommendation':
            '💡 Tingkatkan tabungan Anda! Saat ini Anda hanya menabung ${savingsRate.toStringAsFixed(1)}% dari pendapatan. Target ideal adalah 20-30% untuk kesehatan finansial yang baik.',
        'potential_savings': potentialSavings,
        'priority': 'high',
        'category': 'savings',
        'icon': 'flash',
        'confidence': confidence,
        'impact': impact,
        'actionability': actionability,
        'score': score,
        'action': 'review_budget',
      });
    }

    // Recommendation 2: High spending in one category
    if (highestCategory != null &&
        totalExpense > 0 &&
        (highestAmount / totalExpense) > 0.4) {
      final percentage = ((highestAmount / totalExpense) * 100).toStringAsFixed(
        0,
      );
      final confidence = _calculateConfidence(
        dataQuality: transactionCount > 5 ? 0.8 : 0.5,
        patternStrength: (highestAmount / totalExpense).clamp(0.0, 1.0),
        urgency: 0.7,
      );
      final potentialSavings = highestAmount * 0.15;
      final impact = _calculateImpactScore(
        potentialSavings: potentialSavings,
        totalIncome: totalIncome,
      );
      final actionability = _calculateActionabilityScore(
        action: 'create_budget',
        category: highestCategory,
      );
      final score = _calculateRecommendationScore(
        confidence: confidence,
        impact: impact,
        actionability: actionability,
        relevance: 0.8,
        timing: _getTemporalRelevance(),
      );
      allRecs.add({
        'recommendation':
            '📊 Pengeluaran "$highestCategory" Anda tinggi ($percentage% dari total). Coba kurangi 15% untuk menghemat Rp ${(highestAmount * 0.15).toInt()}/bulan.',
        'potential_savings': potentialSavings,
        'priority': 'medium',
        'category': highestCategory,
        'icon': 'warning_2',
        'confidence': confidence,
        'impact': impact,
        'actionability': actionability,
        'score': score,
        'action': 'create_budget',
      });
    }

    // Recommendation 3: No active goals
    if (goals.isEmpty) {
      final actionability = _calculateActionabilityScore(
        action: 'set_goal',
        category: 'goals',
      );
      final score = _calculateRecommendationScore(
        confidence: 0.9,
        impact: 0.5,
        actionability: actionability,
        relevance: 0.9,
        timing: _getTemporalRelevance(),
      );
      allRecs.add({
        'recommendation':
            '🎯 Buat target finansial! Orang dengan tujuan keuangan yang jelas 42% lebih berhasil mencapai stabilitas finansial. Mulai dengan goal kecil seperti dana darurat.',
        'potential_savings': 0,
        'priority': 'medium',
        'category': 'goals',
        'icon': 'medal',
        'confidence': 0.9,
        'impact': 0.5,
        'actionability': actionability,
        'score': score,
        'action': 'set_goal',
      });
    }

    // Recommendation 4: Budget exceeded
    for (var budget in budgets) {
      // Map database field names to expected field names
      final spentAmount = budget['spent_amount_232143'] ?? budget['spent'];
      final budgetAmount =
          budget['amount_232143'] ?? budget['limit'] ?? budget['amount'];
      final spent = ((spentAmount as num?) ?? 0).toDouble();
      final limit = ((budgetAmount as num?) ?? 1).toDouble();
      if (spent > limit) {
        final categoryName =
            budget['category_name'] ?? budget['name_232143'] ?? 'Unknown';
        final confidence = _calculateConfidence(
          dataQuality: 0.9,
          patternStrength: ((spent - limit) / limit).clamp(0.0, 1.0),
          urgency: 1.0,
        );
        final potentialSavings = spent - limit;
        final impact = _calculateImpactScore(
          potentialSavings: potentialSavings,
          totalIncome: totalIncome,
        );
        final actionability = _calculateActionabilityScore(
          action: 'review_budget',
          category: categoryName,
        );
        final score = _calculateRecommendationScore(
          confidence: confidence,
          impact: impact,
          actionability: actionability,
          relevance: 1.0,
          timing: _getTemporalRelevance(),
        );
        allRecs.add({
          'recommendation':
              '⚠️ Budget "$categoryName" melebihi batas! Anda telah menghabiskan Rp ${spent.toInt()} dari budget Rp ${limit.toInt()}. Pertimbangkan untuk mengurangi pengeluaran kategori ini.',
          'potential_savings': potentialSavings,
          'priority': 'high',
          'category': categoryName,
          'icon': 'danger',
          'confidence': confidence,
          'impact': impact,
          'actionability': actionability,
          'score': score,
          'action': 'review_budget',
        });
      }
    }

    // Add trend-based recommendations
    final expenseTrend = trends['expense_trend'] as String?;
    final expenseChangePercent =
        (trends['expense_change_percent'] as num?)?.toDouble() ?? 0.0;
    if (expenseTrend == 'increasing' && expenseChangePercent > 15) {
      final potentialSavings = totalExpense * 0.1;
      final impact = _calculateImpactScore(
        potentialSavings: potentialSavings,
        totalIncome: totalIncome,
      );
      final actionability = _calculateActionabilityScore(
        action: 'review_spending',
        category: 'trend_alert',
      );
      final score = _calculateRecommendationScore(
        confidence: transactionCount > 20 ? 0.9 : 0.7,
        impact: impact,
        actionability: actionability,
        relevance: 0.9,
        timing: _getTemporalRelevance(),
      );
      allRecs.add({
        'recommendation':
            '📈 Tren pengeluaran meningkat ${expenseChangePercent.toStringAsFixed(0)}% dalam 3 bulan terakhir. Pertimbangkan untuk meninjau kembali pengeluaran rutin Anda.',
        'potential_savings': potentialSavings,
        'priority': 'high',
        'category': 'trend_alert',
        'icon': 'trending_up',
        'confidence': transactionCount > 20 ? 0.9 : 0.7,
        'impact': impact,
        'actionability': actionability,
        'score': score,
        'action': 'review_spending',
      });
    }

    // Day-of-week pattern recommendation
    final peakDay = dayOfWeekPatterns['peak_day'] as String?;
    final peakDayAmount =
        (dayOfWeekPatterns['peak_day_amount'] as num?)?.toDouble() ?? 0.0;
    final avgPerDay =
        (dayOfWeekPatterns['average_per_day'] as num?)?.toDouble() ?? 0.0;
    if (peakDay != null && peakDayAmount > avgPerDay * 1.3) {
      final confidence = _calculateConfidence(
        dataQuality: transactionCount > 15 ? 0.8 : 0.6,
        patternStrength: ((peakDayAmount - avgPerDay) / avgPerDay).clamp(
          0.0,
          1.0,
        ),
        urgency: 0.6,
      );
      final potentialSavings = (peakDayAmount - avgPerDay) * 0.2;
      final impact = _calculateImpactScore(
        potentialSavings: potentialSavings,
        totalIncome: totalIncome,
      );
      final actionability = _calculateActionabilityScore(
        action: 'plan_spending',
        category: 'pattern_insight',
      );
      final score = _calculateRecommendationScore(
        confidence: confidence,
        impact: impact,
        actionability: actionability,
        relevance: 0.7,
        timing: _getTemporalRelevance(),
      );
      allRecs.add({
        'recommendation':
            '📅 Pola pengeluaran: Anda cenderung menghabiskan lebih banyak pada hari $peakDay (Rp ${peakDayAmount.toInt()}). Pertimbangkan untuk merencanakan pengeluaran besar di hari lain.',
        'potential_savings': potentialSavings,
        'priority': 'medium',
        'category': 'pattern_insight',
        'icon': 'calendar_today',
        'confidence': confidence,
        'impact': impact,
        'actionability': actionability,
        'score': score,
        'action': 'plan_spending',
      });
    }

    // Sort by score
    allRecs.sort((a, b) {
      final scoreA = (a['score'] as num?)?.toDouble() ?? 0.0;
      final scoreB = (b['score'] as num?)?.toDouble() ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    return allRecs;
  }

  Map<String, dynamic> _selectBestRecommendation(
    Map<String, dynamic> analysis,
    List<dynamic> budgets,
    List<dynamic> goals,
  ) {
    final savingsRate = (analysis['savingsRate'] as num?)?.toDouble() ?? 0.0;
    final totalExpense = (analysis['totalExpense'] as num?)?.toDouble() ?? 0.0;
    final totalIncome = (analysis['totalIncome'] as num?)?.toDouble() ?? 0.0;
    final highestCategory = analysis['highestCategory'] as String?;
    final highestAmount =
        (analysis['highestAmount'] as num?)?.toDouble() ?? 0.0;
    final transactionCount = analysis['transactionCount'] as int? ?? 0;

    // Enhanced analysis data
    final trendsRaw = analysis['trends'];
    final trends =
        trendsRaw is Map
            ? Map<String, dynamic>.from(
              trendsRaw.map((key, value) => MapEntry(key.toString(), value)),
            )
            : <String, dynamic>{};
    final dayOfWeekPatternsRaw = analysis['day_of_week_patterns'];
    final dayOfWeekPatterns =
        dayOfWeekPatternsRaw is Map
            ? Map<String, dynamic>.from(
              dayOfWeekPatternsRaw.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
            : <String, dynamic>{};
    final frequentMerchants =
        analysis['frequent_merchants'] as List<dynamic>? ?? [];

    // Calculate confidence scores for each recommendation
    final recommendations = <Map<String, dynamic>>[];

    // Enhanced recommendation: Trend-based alerts
    final expenseTrend = trends['expense_trend'] as String?;
    final expenseChangePercent =
        (trends['expense_change_percent'] as num?)?.toDouble() ?? 0.0;
    if (expenseTrend == 'increasing' && expenseChangePercent > 15) {
      final confidence = _calculateConfidence(
        dataQuality: transactionCount > 20 ? 0.9 : 0.7,
        patternStrength: (expenseChangePercent / 50).clamp(0.0, 1.0),
        urgency: 0.9,
      );
      recommendations.add({
        'recommendation':
            '📈 Tren pengeluaran meningkat ${expenseChangePercent.toStringAsFixed(0)}% dalam 3 bulan terakhir. Pertimbangkan untuk meninjau kembali pengeluaran rutin Anda.',
        'potential_savings': totalExpense * 0.1, // 10% reduction potential
        'priority': 'high',
        'category': 'trend_alert',
        'icon': 'trending_up',
        'confidence': confidence,
        'action': 'review_spending',
      });
    }

    // Enhanced recommendation: Day-of-week pattern
    final peakDay = dayOfWeekPatterns['peak_day'] as String?;
    final peakDayAmount =
        (dayOfWeekPatterns['peak_day_amount'] as num?)?.toDouble() ?? 0.0;
    final avgPerDay =
        (dayOfWeekPatterns['average_per_day'] as num?)?.toDouble() ?? 0.0;
    if (peakDay != null && peakDayAmount > avgPerDay * 1.3) {
      final confidence = _calculateConfidence(
        dataQuality: transactionCount > 15 ? 0.8 : 0.6,
        patternStrength: ((peakDayAmount - avgPerDay) / avgPerDay).clamp(
          0.0,
          1.0,
        ),
        urgency: 0.6,
      );
      recommendations.add({
        'recommendation':
            '📅 Pola pengeluaran: Anda cenderung menghabiskan lebih banyak pada hari $peakDay (Rp ${peakDayAmount.toInt()}). Pertimbangkan untuk merencanakan pengeluaran besar di hari lain.',
        'potential_savings': (peakDayAmount - avgPerDay) * 0.2,
        'priority': 'medium',
        'category': 'pattern_insight',
        'icon': 'calendar_today',
        'confidence': confidence,
        'action': 'plan_spending',
      });
    }

    // Enhanced recommendation: Frequent merchants
    if (frequentMerchants.isNotEmpty) {
      final topMerchant = frequentMerchants.first as Map<String, dynamic>;
      final merchantFreq = topMerchant['frequency'] as int? ?? 0;
      if (merchantFreq >= 5) {
        final confidence = _calculateConfidence(
          dataQuality: 0.9,
          patternStrength: (merchantFreq / 10).clamp(0.0, 1.0),
          urgency: 0.5,
        );
        recommendations.add({
          'recommendation':
              '🛒 Anda sering bertransaksi di "${topMerchant['merchant']}" ($merchantFreq kali). Pertimbangkan untuk membuat budget khusus atau mencari alternatif yang lebih hemat.',
          'potential_savings': 0, // Hard to quantify
          'priority': 'low',
          'category': 'merchant_insight',
          'icon': 'store',
          'confidence': confidence,
          'action': 'review_merchant',
        });
      }
    }

    // Recommendation 1: Low or negative savings rate
    if (savingsRate < 10) {
      final potentialSavings = totalIncome * 0.2 - (totalIncome - totalExpense);
      final confidence = _calculateConfidence(
        dataQuality: transactionCount > 10 ? 0.9 : 0.6,
        patternStrength:
            (10 - savingsRate) / 10, // Lower savings = higher confidence
        urgency: 1.0,
      );
      final impact = _calculateImpactScore(
        potentialSavings: potentialSavings,
        totalIncome: totalIncome,
      );
      final actionability = _calculateActionabilityScore(
        action: 'review_budget',
        category: 'savings',
      );
      final score = _calculateRecommendationScore(
        confidence: confidence,
        impact: impact,
        actionability: actionability,
        relevance: 1.0,
        timing: _getTemporalRelevance(),
      );
      recommendations.add({
        'recommendation':
            '💡 Tingkatkan tabungan Anda! Saat ini Anda hanya menabung ${savingsRate.toStringAsFixed(1)}% dari pendapatan. Target ideal adalah 20-30% untuk kesehatan finansial yang baik.',
        'potential_savings': potentialSavings,
        'priority': 'high',
        'category': 'savings',
        'icon': 'flash',
        'confidence': confidence,
        'impact': impact,
        'actionability': actionability,
        'score': score,
        'action': 'review_budget',
      });
    }

    // Recommendation 2: High spending in one category
    if (highestCategory != null &&
        totalExpense > 0 &&
        (highestAmount / totalExpense) > 0.4) {
      final percentage = ((highestAmount / totalExpense) * 100).toStringAsFixed(
        0,
      );
      final confidence = _calculateConfidence(
        dataQuality: transactionCount > 5 ? 0.8 : 0.5,
        patternStrength: (highestAmount / totalExpense).clamp(0.0, 1.0),
        urgency: 0.7,
      );
      recommendations.add({
        'recommendation':
            '📊 Pengeluaran "$highestCategory" Anda tinggi ($percentage% dari total). Coba kurangi 15% untuk menghemat Rp ${(highestAmount * 0.15).toInt()}/bulan.',
        'potential_savings': highestAmount * 0.15,
        'priority': 'medium',
        'category': highestCategory,
        'icon': 'warning_2',
        'confidence': confidence,
      });
    }

    // Recommendation 3: No active goals
    if (goals.isEmpty) {
      recommendations.add({
        'recommendation':
            '🎯 Buat target finansial! Orang dengan tujuan keuangan yang jelas 42% lebih berhasil mencapai stabilitas finansial. Mulai dengan goal kecil seperti dana darurat.',
        'potential_savings': 0,
        'priority': 'medium',
        'category': 'goals',
        'icon': 'medal',
        'confidence': 0.9, // High confidence - always relevant
      });
    }

    // Recommendation 4: Budget exceeded
    for (var budget in budgets) {
      // Map database field names to expected field names
      final spentAmount = budget['spent_amount_232143'] ?? budget['spent'];
      final budgetAmount =
          budget['amount_232143'] ?? budget['limit'] ?? budget['amount'];
      final spent = ((spentAmount as num?) ?? 0).toDouble();
      final limit = ((budgetAmount as num?) ?? 1).toDouble();
      if (spent > limit) {
        final categoryName =
            budget['category_name'] ?? budget['name_232143'] ?? 'Unknown';
        final confidence = _calculateConfidence(
          dataQuality: 0.9,
          patternStrength: ((spent - limit) / limit).clamp(0.0, 1.0),
          urgency: 1.0,
        );
        recommendations.add({
          'recommendation':
              '⚠️ Budget "$categoryName" melebihi batas! Anda telah menghabiskan Rp ${spent.toInt()} dari budget Rp ${limit.toInt()}. Pertimbangkan untuk mengurangi pengeluaran kategori ini.',
          'potential_savings': spent - limit,
          'priority': 'high',
          'category': categoryName,
          'icon': 'danger',
          'confidence': confidence,
        });
      }
    }

    // Recommendation 5: Good savings rate - encourage
    if (savingsRate >= 20) {
      recommendations.add({
        'recommendation':
            '🌟 Luar biasa! Tingkat tabungan Anda ${savingsRate.toStringAsFixed(0)}% sangat baik. Pertimbangkan untuk mengalokasikan lebih banyak ke investasi jangka panjang atau goal Anda.',
        'potential_savings': 0,
        'priority': 'low',
        'category': 'achievement',
        'icon': 'award',
        'confidence': 0.8,
      });
    }

    // Recommendation 6: Moderate savings - suggestions
    if (savingsRate >= 10 && savingsRate < 20) {
      recommendations.add({
        'recommendation':
            '💪 Bagus! Tingkat tabungan ${savingsRate.toStringAsFixed(0)}% cukup solid. Coba tingkatkan 5% lagi dengan mengurangi pengeluaran tidak penting seperti langganan yang jarang dipakai.',
        'potential_savings': totalIncome * 0.05,
        'priority': 'low',
        'category': 'improvement',
        'icon': 'trend_up',
        'confidence': 0.6,
      });
    }

    // Calculate scores for all recommendations if not already calculated
    for (var rec in recommendations) {
      if (!rec.containsKey('score')) {
        final potentialSavings =
            (rec['potential_savings'] as num?)?.toDouble() ?? 0.0;
        final impact =
            (rec['impact'] as num?)?.toDouble() ??
            _calculateImpactScore(
              potentialSavings: potentialSavings,
              totalIncome: totalIncome,
            );
        final actionability =
            (rec['actionability'] as num?)?.toDouble() ??
            _calculateActionabilityScore(
              action: rec['action'] as String?,
              category: rec['category'] as String? ?? 'general',
            );
        final score = _calculateRecommendationScore(
          confidence: (rec['confidence'] as num?)?.toDouble() ?? 0.5,
          impact: impact,
          actionability: actionability,
          relevance: 0.8,
          timing: _getTemporalRelevance(),
        );
        rec['impact'] = impact;
        rec['actionability'] = actionability;
        rec['score'] = score;
      }
    }

    // Sort by score (highest first) and return best
    if (recommendations.isNotEmpty) {
      recommendations.sort((a, b) {
        final scoreA =
            (a['score'] as num?)?.toDouble() ??
            (a['confidence'] as num?)?.toDouble() ??
            0.0;
        final scoreB =
            (b['score'] as num?)?.toDouble() ??
            (b['confidence'] as num?)?.toDouble() ??
            0.0;
        return scoreB.compareTo(scoreA);
      });
      return recommendations.first;
    }

    // Default recommendation
    return _getDefaultRecommendation();
  }

  /// Calculate confidence score for a recommendation
  double _calculateConfidence({
    required double dataQuality,
    required double patternStrength,
    required double urgency,
  }) {
    // Weighted average: data quality (40%), pattern strength (30%), urgency (30%)
    return (dataQuality * 0.4) + (patternStrength * 0.3) + (urgency * 0.3);
  }

  /// Calculate impact score (potential savings impact)
  double _calculateImpactScore({
    required double potentialSavings,
    required double totalIncome,
  }) {
    if (totalIncome == 0) return 0.0;
    // Impact is higher if potential savings is a larger percentage of income
    final savingsPercent = (potentialSavings / totalIncome) * 100;
    return (savingsPercent / 20).clamp(0.0, 1.0); // Max impact at 20% of income
  }

  /// Calculate actionability score (how easy it is to act on)
  double _calculateActionabilityScore({
    required String? action,
    required String category,
  }) {
    double score = 0.5; // Base score

    // Higher score for specific actions
    if (action != null) {
      if (action == 'create_budget' || action == 'set_goal') {
        score = 0.9; // Very actionable
      } else if (action == 'review_budget' || action == 'adjust_budget') {
        score = 0.8; // Highly actionable
      } else if (action == 'plan_spending' || action == 'review_spending') {
        score = 0.7; // Moderately actionable
      }
    }

    // Adjust based on category specificity
    if (category != 'general' && category != 'trend_alert') {
      score += 0.1; // More specific = more actionable
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate overall recommendation score
  double _calculateRecommendationScore({
    required double confidence,
    required double impact,
    required double actionability,
    required double relevance,
    double timing = 0.5,
  }) {
    // Formula: impact (40%) + actionability (30%) + relevance (20%) + timing (10%)
    return (impact * 0.4) +
        (actionability * 0.3) +
        (relevance * 0.2) +
        (timing * 0.1);
  }

  Map<String, dynamic> _getDefaultRecommendation() {
    return {
      'recommendation':
          '📈 Terus pantau keuangan Anda! Catat setiap transaksi untuk mendapat insight yang lebih baik tentang pola pengeluaran Anda.',
      'potential_savings': 0,
      'priority': 'low',
      'category': 'general',
      'icon': 'chart',
      'confidence': 0.5,
    };
  }

  /// Parse natural language query (simple keyword-based)
  /// Example: "Can I afford 2M phone?" -> {canAfford: bool, reasoning: String, amount: Money}
  Future<Map<String, dynamic>> parseNaturalLanguageQuery(String query) async {
    try {
      // Convert to lowercase for matching
      final lowerQuery = query.toLowerCase();

      // Extract amount (look for numbers followed by M, K, or plain numbers)
      double? amount;
      final amountRegex = RegExp(
        r'(\d+(?:\.\d+)?)\s*(?:m|jt|juta|k|rb|ribu)?',
        caseSensitive: false,
      );
      final match = amountRegex.firstMatch(lowerQuery);
      if (match != null) {
        final number = double.parse(match.group(1)!);
        final unit = match.group(2)?.toLowerCase() ?? '';
        if (unit.contains('m') ||
            unit.contains('juta') ||
            unit.contains('jt')) {
          amount = number * 1000000;
        } else if (unit.contains('k') ||
            unit.contains('rb') ||
            unit.contains('ribu')) {
          amount = number * 1000;
        } else {
          amount = number;
        }
      }

      // Detect keywords
      final hasAffordKeyword =
          lowerQuery.contains('afford') ||
          lowerQuery.contains('beli') ||
          lowerQuery.contains('bisa') ||
          lowerQuery.contains('can i');

      if (!hasAffordKeyword || amount == null) {
        return {
          'canAfford': null,
          'reasoning':
              'Tidak dapat memahami pertanyaan. Coba: "Bisakah saya beli [jumlah]?"',
          'amount': null,
        };
      }

      // Get current balance
      final transactionsData = await _apiService.getTransactions(limit: 100);
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
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

      double totalIncome = 0;
      double totalExpense = 0;
      for (var t in thisMonthTransactions) {
        final amt = (t['amount'] ?? 0).toDouble();
        final type = t['type']?.toString().toLowerCase() ?? 'expense';
        if (type == 'income') {
          totalIncome += amt;
        } else {
          totalExpense += amt;
        }
      }

      final currentBalance = totalIncome - totalExpense;
      final canAfford = currentBalance >= amount;

      // Get forecast for next 30 days
      final forecast = await _expensePredictor.predictNext30Days(
        transactions:
            thisMonthTransactions
                .map((t) => t as Map<String, dynamic>)
                .toList(),
      );
      final forecastAmount =
          (forecast['forecastAmount'] as num?)?.toDouble() ?? 0.0;
      final projectedBalance = currentBalance - forecastAmount;

      String reasoning;
      if (canAfford) {
        reasoning =
            'Ya, Anda bisa membeli item seharga ${amount.toInt()}. Saldo saat ini: Rp ${currentBalance.toInt()}.';
        if (projectedBalance < amount) {
          reasoning +=
              ' Namun, dengan prediksi pengeluaran 30 hari ke depan, saldo proyeksi: Rp ${projectedBalance.toInt()}.';
        }
      } else {
        final shortfall = amount - currentBalance;
        reasoning =
            'Tidak, saldo saat ini (Rp ${currentBalance.toInt()}) tidak cukup. Kekurangan: Rp ${shortfall.toInt()}.';
      }

      return {
        'canAfford': canAfford,
        'reasoning': reasoning,
        'amount': amount,
        'currentBalance': currentBalance,
        'projectedBalance': projectedBalance,
      };
    } catch (e) {
      LoggerService.error('Error parsing natural language query', error: e);
      return {
        'canAfford': null,
        'reasoning': 'Terjadi kesalahan saat memproses pertanyaan.',
        'amount': null,
      };
    }
  }

  /// Get expense forecast for next 30 days
  Future<Map<String, dynamic>> getExpenseForecast() async {
    try {
      final transactionsData = await _apiService.getTransactions(limit: 100);
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
      return await _expensePredictor.predictNext30Days(
        transactions:
            transactions.map((t) => t as Map<String, dynamic>).toList(),
      );
    } catch (e) {
      LoggerService.error('Error getting expense forecast', error: e);
      return {
        'forecast': null,
        'forecastAmount': 0.0,
        'confidence': 0.0,
        'trend': 'error',
        'message': 'Terjadi kesalahan saat memprediksi pengeluaran',
      };
    }
  }

  /// Get spending insights for a specific period
  Future<Map<String, dynamic>> getSpendingInsights(String period) async {
    try {
      final transactionsData = await _apiService.getTransactions(limit: 200);
      final transactions = List<dynamic>.from(
        transactionsData['transactions'] ?? [],
      );
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
      LoggerService.error('Error getting spending insights', error: e);
      return {};
    }
  }

  /// Get temporal relevance score (0.0 to 1.0)
  /// Higher score for time-sensitive recommendations (e.g., end of month)
  double _getTemporalRelevance() {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final dayOfWeek = now.weekday;

    // Higher relevance at end of month (budget alerts)
    if (dayOfMonth >= 25) {
      return 0.9;
    }
    // Higher relevance on weekends (spending planning)
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      return 0.7;
    }
    // Higher relevance at start of month (fresh start)
    if (dayOfMonth <= 5) {
      return 0.8;
    }
    return 0.5; // Default
  }

  /// Generate contextual recommendations based on time and events
  Future<List<Map<String, dynamic>>> _generateContextualRecommendations(
    Map<String, dynamic> analysis,
    List<dynamic> budgets,
    List<dynamic> goals,
  ) async {
    final contextualRecs = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final dayOfWeek = now.weekday;

    // Month-end budget alerts
    if (dayOfMonth >= 25) {
      final totalExpense =
          (analysis['totalExpense'] as num?)?.toDouble() ?? 0.0;
      final totalIncome = (analysis['totalIncome'] as num?)?.toDouble() ?? 0.0;
      final remainingDays =
          DateTime(now.year, now.month + 1, 0).day - dayOfMonth;
      final dailyAverage = totalExpense / dayOfMonth;
      final projectedMonthEnd = totalExpense + (dailyAverage * remainingDays);

      if (projectedMonthEnd > totalIncome * 0.9) {
        contextualRecs.add({
          'recommendation':
              '📅 Akhir bulan mendekat! Berdasarkan pola pengeluaran, Anda diperkirakan menghabiskan ${projectedMonthEnd.toInt()} dari ${totalIncome.toInt()} bulan ini. Pertimbangkan untuk mengurangi pengeluaran di ${remainingDays} hari tersisa.',
          'potential_savings': projectedMonthEnd - totalIncome,
          'priority': 'high',
          'category': 'month_end_alert',
          'icon': 'calendar',
          'confidence': 0.85,
          'action': 'review_budget',
          'temporal': true,
        });
      }
    }

    // Payday recommendations (assuming payday is around 25th-28th or 1st-5th)
    if ((dayOfMonth >= 25 && dayOfMonth <= 28) ||
        (dayOfMonth >= 1 && dayOfMonth <= 5)) {
      final savingsRate = (analysis['savingsRate'] as num?)?.toDouble() ?? 0.0;
      if (savingsRate < 20) {
        contextualRecs.add({
          'recommendation':
              '💰 Hari gajian! Ini waktu yang tepat untuk mengalokasikan tabungan. Targetkan ${(20 - savingsRate).toStringAsFixed(0)}% tambahan dari pendapatan bulan ini.',
          'potential_savings': 0,
          'priority': 'medium',
          'category': 'payday_reminder',
          'icon': 'money',
          'confidence': 0.8,
          'action': 'set_savings_goal',
          'temporal': true,
        });
      }
    }

    // Weekend spending planning
    if (dayOfWeek == 6 || dayOfWeek == 7) {
      final dayOfWeekPatternsRaw = analysis['day_of_week_patterns'];
      final dayOfWeekPatterns =
          dayOfWeekPatternsRaw is Map
              ? Map<String, dynamic>.from(
                dayOfWeekPatternsRaw.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              )
              : <String, dynamic>{};
      final peakDay = dayOfWeekPatterns['peak_day'] as String?;
      if (peakDay != null && (dayOfWeek == 6 || dayOfWeek == 7)) {
        contextualRecs.add({
          'recommendation':
              '📅 Akhir pekan! Berdasarkan pola Anda, pengeluaran cenderung lebih tinggi di akhir pekan. Rencanakan pengeluaran dengan bijak.',
          'potential_savings': 0,
          'priority': 'low',
          'category': 'weekend_planning',
          'icon': 'weekend',
          'confidence': 0.7,
          'action': 'plan_spending',
          'temporal': true,
        });
      }
    }

    // Goal progress integration
    for (var goal in goals) {
      final goalProgress = (goal['current_amount'] as num?)?.toDouble() ?? 0.0;
      final goalTarget = (goal['target_amount'] as num?)?.toDouble() ?? 0.0;
      final progressPercent =
          goalTarget > 0 ? (goalProgress / goalTarget) * 100 : 0;

      if (progressPercent > 50 && progressPercent < 80) {
        // Mid-way through goal
        contextualRecs.add({
          'recommendation':
              '🎯 Goal "${goal['name']}" sudah ${progressPercent.toStringAsFixed(0)}% tercapai! Tetap konsisten untuk mencapai target.',
          'potential_savings': 0,
          'priority': 'medium',
          'category': 'goal_progress',
          'icon': 'target',
          'confidence': 0.75,
          'action': 'view_goal',
          'goal_id': goal['id'],
        });
      }
    }

    // Obligation-aware suggestions (upcoming bills)
    try {
      final obligations = await _apiService.getObligations();
      final upcomingBills = <Map<String, dynamic>>[];
      final today = DateTime(now.year, now.month, now.day);

      for (var obligation in obligations) {
        if (obligation['status_232143'] != 'active') continue;

        try {
          final dueDateStr = obligation['due_date_232143']?.toString() ?? '';
          if (dueDateStr.isEmpty) continue;

          final dueDate = DateTime.parse(dueDateStr);
          final daysUntilDue = dueDate.difference(today).inDays;

          if (daysUntilDue >= 0 && daysUntilDue <= 7) {
            upcomingBills.add({
              'name': obligation['name_232143'] ?? 'Tagihan',
              'amount': obligation['monthly_amount_232143'] ?? 0.0,
              'days_until': daysUntilDue,
            });
          }
        } catch (e) {
          continue;
        }
      }

      if (upcomingBills.isNotEmpty) {
        final totalUpcoming = upcomingBills.fold<double>(
          0.0,
          (sum, bill) => sum + ((bill['amount'] as num?)?.toDouble() ?? 0.0),
        );
        final nearestBill = upcomingBills.reduce(
          (a, b) => (a['days_until'] as int) < (b['days_until'] as int) ? a : b,
        );

        contextualRecs.add({
          'recommendation':
              '📋 ${upcomingBills.length} tagihan akan jatuh tempo dalam 7 hari ke depan (Total: ${totalUpcoming.toInt()}). Pastikan dana tersedia untuk "${nearestBill['name']}" yang jatuh tempo dalam ${nearestBill['days_until']} hari.',
          'potential_savings': 0,
          'priority': 'high',
          'category': 'upcoming_bills',
          'icon': 'receipt',
          'confidence': 0.9,
          'action': 'view_obligations',
          'temporal': true,
        });
      }
    } catch (e) {
      LoggerService.warning(
        'Could not fetch obligations for contextual recommendations',
        error: e,
      );
    }

    return contextualRecs;
  }

  /// Track recommendation feedback
  Future<void> trackRecommendationFeedback({
    required String recommendationId,
    required String recommendationType,
    required String action,
  }) async {
    await _personalizer.trackFeedback(
      recommendationId: recommendationId,
      recommendationType: recommendationType,
      action: action,
    );
  }

  /// Generate personalized tips based on spending patterns
  List<String> generateSmartTips(Map<String, dynamic> analysis) {
    final tips = <String>[];
    final savingsRate = (analysis['savingsRate'] as num?)?.toDouble() ?? 0.0;
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
