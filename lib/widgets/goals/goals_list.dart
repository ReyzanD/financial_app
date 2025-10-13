import 'package:flutter/material.dart';
import 'package:financial_app/widgets/goals/goal_card.dart';

class GoalsList extends StatelessWidget {
  const GoalsList({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = [
      {
        'id': '1',
        'name': 'Dana Darurat',
        'target': 10000000,
        'saved': 6500000,
        'deadline': '2024-06-30',
        'type': 'emergency_fund',
        'priority': 'high',
      },
      {
        'id': '2',
        'name': 'Liburan ke Bali',
        'target': 5000000,
        'saved': 2500000,
        'deadline': '2024-04-15',
        'type': 'vacation',
        'priority': 'medium',
      },
      {
        'id': '3',
        'name': 'Upgrade Laptop',
        'target': 8000000,
        'saved': 3000000,
        'deadline': '2024-08-31',
        'type': 'electronics',
        'priority': 'low',
      },
    ];

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
