import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/widgets/goals/goals_helpers.dart';

class GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;

  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final target = goal['target'] as int;
    final saved = goal['saved'] as int;
    final progress = saved / target;
    final deadline = goal['deadline'] as String;
    final type = goal['type'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: getGoalTypeColor(type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  getGoalTypeIcon(type),
                  color: getGoalTypeColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['name'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Target: Rp ${target.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPriorityBadge(goal['priority'] as String),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            color: getGoalTypeColor(type),
            borderRadius: BorderRadius.circular(10),
          ),

          const SizedBox(height: 8),

          // Progress Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${saved.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Text(
                formatDeadline(deadline),
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String text;

    switch (priority) {
      case 'high':
        color = Colors.red;
        text = 'Tinggi';
        break;
      case 'medium':
        color = Colors.orange;
        text = 'Sedang';
        break;
      case 'low':
        color = Colors.green;
        text = 'Rendah';
        break;
      default:
        color = Colors.grey;
        text = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
