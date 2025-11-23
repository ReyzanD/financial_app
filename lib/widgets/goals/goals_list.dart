import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financial_app/widgets/goals/goal_card.dart';
import 'package:financial_app/services/api_service.dart';

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
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
        ),
      );
    }

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
          return GoalCard(goal: goal, onUpdated: widget.onGoalsChanged);
        },
      ),
    );
  }
}
