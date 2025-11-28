import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/widgets/goals/goal_card.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/widgets/common/shimmer_loading.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/utils/page_transitions.dart';

class GoalsList extends StatefulWidget {
  final VoidCallback? onGoalsChanged;

  const GoalsList({super.key, this.onGoalsChanged});

  @override
  State<GoalsList> createState() => _GoalsListState();
}

class _GoalsListState extends State<GoalsList> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final fetchedGoals = await _apiService.getGoals();
      if (mounted) {
        setState(() {
          goals =
              fetchedGoals.map((goal) {
                return {
                  'id': goal['id'],
                  'name': goal['name'],
                  'target': goal['target'],
                  'saved': goal['saved'],
                  'deadline': goal['deadline'],
                  'type': goal['type'],
                  'priority': goal['priority'] ?? 3,
                  'progress': goal['progress'] ?? 0,
                  'description': goal['description'],
                };
              }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Show error or keep empty state
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Expanded(
        child: CardListShimmer(itemCount: 4, cardHeight: 180),
      );
    }

    if (goals.isEmpty) {
      return Expanded(
        child: EmptyState(
          icon: Icons.flag_outlined,
          title: 'Belum Ada Target',
          subtitle: 'Tetapkan target keuangan dan capai impian Anda',
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return StaggeredListAnimation(
            index: index,
            child: GoalCard(goal: goal, onUpdated: widget.onGoalsChanged),
          );
        },
      ),
    );
  }
}
