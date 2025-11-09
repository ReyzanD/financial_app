import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/widgets/goals/goal_card.dart';

class GoalsList extends StatefulWidget {
  const GoalsList({super.key});

  @override
  State<GoalsList> createState() => _GoalsListState();
}

class _GoalsListState extends State<GoalsList> {
  List<Map<String, dynamic>> goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    if (!onboardingCompleted) {
      // New user - show default goals
      goals = [
        {
          'id': '1',
          'name': 'Dana Darurat',
          'target': 10000000,
          'saved': 0,
          'deadline': '2024-12-31',
          'type': 'emergency_fund',
          'priority': 'high',
        },
        {
          'id': '2',
          'name': 'Liburan Impian',
          'target': 5000000,
          'saved': 0,
          'deadline': '2024-12-31',
          'type': 'vacation',
          'priority': 'medium',
        },
        {
          'id': '3',
          'name': 'Investasi Awal',
          'target': 3000000,
          'saved': 0,
          'deadline': '2024-12-31',
          'type': 'investment',
          'priority': 'medium',
        },
      ];
    } else {
      // Existing user - load from database (for now, show empty state)
      goals = [];
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag_outlined, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Belum ada tujuan keuangan',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan tujuan pertama Anda',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          return GoalCard(goal: goal);
        },
      ),
    );
  }
}
