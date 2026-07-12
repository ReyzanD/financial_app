import 'package:flutter/material.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/goals/goal_card.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/common/shimmer_loading.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/utils/page_transitions.dart';
import 'package:financial_app/utils/design_tokens.dart';

class GoalsList extends StatefulWidget {
  final VoidCallback? onGoalsChanged;
  final List<Map<String, dynamic>>? initialGoals;

  const GoalsList({super.key, this.onGoalsChanged, this.initialGoals});

  @override
  State<GoalsList> createState() => _GoalsListState();
}

class _GoalsListState extends State<GoalsList> {
  final GoalDataService _goalService = GoalDataService();
  List<Map<String, dynamic>> goals = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialGoals != null) {
      goals = List<Map<String, dynamic>>.from(widget.initialGoals!);
      _isLoading = false;
    } else {
      _loadGoals();
    }
  }

  Future<void> _loadGoals() async {
    _hasError = false;
    try {
      final fetchedGoals = await _goalService.getGoals();
      if (mounted) {
        setState(() {
          goals = List<Map<String, dynamic>>.from(fetchedGoals);
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading goals', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CardListShimmer(itemCount: 4, cardHeight: 180);
    }

    if (goals.isEmpty && !_hasError) {
      final l10n = AppLocalizations.of(context);
      return SizedBox(
        width: double.infinity,
        child: EmptyState(
          icon: Icons.flag_outlined,
          title: l10n?.no_goals_title ?? 'Belum Ada Target',
          subtitle: 'Tetapkan target keuangan dan capai impian Anda',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return StaggeredListAnimation(
          index: index,
          child: GoalCard(goal: goal, onUpdated: widget.onGoalsChanged),
        );
      },
    );
  }
}
