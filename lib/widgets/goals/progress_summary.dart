import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';

class ProgressSummary extends StatefulWidget {
  final List<Map<String, dynamic>>? initialGoals;

  const ProgressSummary({super.key, this.initialGoals});

  @override
  State<ProgressSummary> createState() => _ProgressSummaryState();
}

class _ProgressSummaryState extends State<ProgressSummary> {
  final GoalDataService _goalService = GoalDataService();
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialGoals != null) {
      _computeSummary(widget.initialGoals!);
    } else {
      _loadSummary();
    }
  }

  void _computeSummary(List<Map<String, dynamic>> goals) {
    double totalTarget = 0.0;
    double totalCurrent = 0.0;
    int completedCount = 0;

    for (final goal in goals) {
      totalTarget += (goal['target_amount_232143'] as num?)?.toDouble() ?? 0.0;
      totalCurrent +=
          (goal['current_amount_232143'] as num?)?.toDouble() ?? 0.0;
      if (goal['is_completed_232143'] == 1) {
        completedCount++;
      }
    }

    _summary = {
      'total_goals': goals.length,
      'total_target': totalTarget,
      'total_saved': totalCurrent,
      'completed_goals': completedCount,
      'avg_progress':
          totalTarget > 0 ? (totalCurrent / totalTarget) * 100 : 0.0,
    };
    _isLoading = false;
  }

  Future<void> _loadSummary() async {
    try {
      final goals = await _goalService.getGoals();
      _computeSummary(goals);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      LoggerService.error('Error loading goals summary', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (context.mounted) {
          ErrorHandlerService.showErrorSnackbar(
            context,
            ErrorHandlerService.getUserFriendlyMessage(e),
            onRetry: _loadSummary,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(DesignTokens.spacing4),
        padding: const EdgeInsets.all(20),
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [DesignTokens.primaryColor, Color(0xFF6A3093)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final totalGoals = _summary['total_goals'] ?? 0;
    final completedGoals = _summary['completed_goals'] ?? 0;
    final totalTarget = _summary['total_target'] ?? 0;
    final totalSaved = _summary['total_saved'] ?? 0;
    final avgProgress = (_summary['avg_progress'] ?? 0) / 100;
    final inProgress = totalGoals - completedGoals;

    return Container(
      margin: const EdgeInsets.all(DesignTokens.spacing4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DesignTokens.primaryColor, Color(0xFF6A3093)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Progress Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: avgProgress.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Colors.white,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(avgProgress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n?.total ?? 'Total',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 20),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatItem(
                  'Target Tercapai',
                  '$completedGoals/$totalGoals',
                  Iconsax.tick_circle,
                ),
                const SizedBox(height: 8),
                _buildStatItem('Dalam Progress', '$inProgress', Iconsax.clock),
                const SizedBox(height: 8),
                _buildStatItem(
                  l10n?.total_target ?? 'Total Target',
                  CurrencyFormatter.formatRupiah(totalTarget),
                  Iconsax.d_cube_scan,
                ),
                const SizedBox(height: 8),
                _buildStatItem(
                  l10n?.total_saved ?? 'Total Tersimpan',
                  CurrencyFormatter.formatRupiah(totalSaved),
                  Iconsax.wallet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
