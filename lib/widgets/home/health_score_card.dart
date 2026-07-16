import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/data/transaction_data_service.dart';
import 'package:financial_app/services/financial_calculator.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/core/di/service_locator.dart';

/// Detailed health score breakdown card for the collapsible dashboard section.
///
/// Fetches financial summary data and calculates the health score,
/// displaying the score, health level, factor breakdowns, and recommendations.
class HealthScoreCard extends StatefulWidget {
  const HealthScoreCard({super.key});

  @override
  State<HealthScoreCard> createState() => _HealthScoreCardState();
}

class _HealthScoreCardState extends State<HealthScoreCard> {
  final TransactionDataService _transactionData = getIt<TransactionDataService>();
  final FinancialCalculator _calculator = FinancialCalculator();

  Map<String, dynamic>? _healthScoreData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHealthScore();
  }

  @override
  void didUpdateWidget(HealthScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget key changes (triggered by refresh counter)
    if (widget.key != oldWidget.key) {
      _loadHealthScore();
    }
  }

  Future<void> _loadHealthScore() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final now = DateTime.now();
      final summary = await _transactionData.getFinancialSummary(
        year: now.year,
        month: now.month,
      );

      if (!mounted) return;

      final summaries = summary['summary'] as Map<String, dynamic>? ?? {};
      final income =
          (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ??
              0.0;
      final expense =
          (summaries['expense'] as Map<String, dynamic>?)?['total_amount'] ??
              0.0;

      final incomeDouble = (income is num) ? income.toDouble() : 0.0;
      final expenseDouble = (expense is num) ? expense.toDouble() : 0.0;
      final balance = incomeDouble - expenseDouble;

      final healthScore = _calculator.calculateFinancialHealthScore(
        income: incomeDouble,
        expenses: expenseDouble,
        savings: balance < 0 ? 0.0 : balance,
      );

      if (mounted) {
        setState(() {
          _healthScoreData = healthScore;
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggerService.error(
        '[HealthScoreCard] Error loading health score',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat skor kesehatan';
        });
      }
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return DesignTokens.successColor;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return DesignTokens.errorColor;
  }

  String _getHealthLevel(double score) {
    if (score >= 80) return 'Sangat Sehat';
    if (score >= 60) return 'Sehat';
    if (score >= 40) return 'Cukup';
    if (score >= 20) return 'Perlu Perbaikan';
    return 'Kritis';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_healthScoreData == null) {
      return const SizedBox.shrink();
    }

    return _buildContent(context);
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(
          color: DesignTokens.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(
          color: DesignTokens.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: DesignTokens.errorColor, size: 32),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadHealthScore,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              l10n?.try_again ?? 'Coba Lagi',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final score = (_healthScoreData!['score'] as num?)?.toDouble() ?? 0.0;
    final level = _getHealthLevel(score);
    final color = _getScoreColor(score);
    final factors =
        _healthScoreData!['factors'] as Map<String, dynamic>? ?? {};
    final recommendations =
        _healthScoreData!['recommendations'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.05), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score circle and level
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(
                      color: color.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      score.toInt().toString(),
                      style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Factor breakdowns
          ...factors.entries.map((entry) {
            final factorScore = (entry.value as num).toDouble();
            final maxScore = _getMaxScore(entry.key);
            final ratio = maxScore > 0 ? factorScore / maxScore : 0.0;
            final factorColor = ratio >= 0.7
                ? DesignTokens.successColor
                : ratio >= 0.4
                ? Colors.orange
                : DesignTokens.errorColor;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getFactorLabel(entry.key),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[300],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${factorScore.toStringAsFixed(0)}/${maxScore.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          color: factorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(factorColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Recommendations section
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: DesignTokens.borderDark),
            const SizedBox(height: 8),
            Text(
              'Rekomendasi',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...recommendations.take(3).map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  double _getMaxScore(String key) {
    switch (key) {
      case 'Savings Rate':
        return 40.0;
      case 'Budget Adherence':
        return 30.0;
      case 'Debt Ratio':
        return 20.0;
      case 'Expense Stability':
        return 10.0;
      default:
        return 100.0;
    }
  }

  String _getFactorLabel(String key) {
    switch (key) {
      case 'Savings Rate':
        return 'Tingkat Tabungan';
      case 'Budget Adherence':
        return 'Kepatuhan Budget';
      case 'Debt Ratio':
        return 'Rasio Utang';
      case 'Expense Stability':
        return 'Stabilitas Pengeluaran';
      default:
        return key;
    }
  }
}
