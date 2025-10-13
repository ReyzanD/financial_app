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
            const ProgressSummary(),

            // Goals List
            const GoalsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalModal,
        backgroundColor: const Color(0xFF8B5FBF),
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  void _showAddGoalModal() {
    showModalBottomSheet(
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
  }
}
