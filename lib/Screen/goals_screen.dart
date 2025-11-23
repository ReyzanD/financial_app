import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/widgets/goals/goals_header.dart';
import 'package:financial_app/widgets/goals/progress_summary.dart';
import 'package:financial_app/widgets/goals/goals_list.dart';
import 'package:financial_app/widgets/goals/add_goal_modal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Use a simple refresh key that changes to rebuild widgets
  int _refreshKey = 0;

  void _refreshGoals() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const GoalsHeader(),

            // Goals Progress Summary
            ProgressSummary(key: ValueKey('progress_$_refreshKey')),

            // Goals List
            GoalsList(
              key: ValueKey('goals_$_refreshKey'),
              onGoalsChanged: _refreshGoals,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goals_fab',
        onPressed: _showAddGoalModal,
        backgroundColor: const Color(0xFF8B5FBF),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  void _showAddGoalModal() async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const AddGoalModal();
      },
    );

    // Refresh the list if a goal was added
    if (result == true) {
      _refreshGoals();
    }
  }
}
