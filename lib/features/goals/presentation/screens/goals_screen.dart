import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/goals/presentation/controllers/goal_controller.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/goals/goals_header.dart';
import 'package:financial_app/widgets/goals/progress_summary.dart';
import 'package:financial_app/widgets/goals/goals_list.dart';
import 'package:financial_app/widgets/goals/add_goal_modal.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/utils/design_tokens.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalDataService _goalDataService = GoalDataService();
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await _goalDataService.getGoals();
      if (mounted) {
        setState(() {
          _goals = List<Map<String, dynamic>>.from(goals);
        });
      }
    } catch (e) {
      LoggerService.error('Error loading goals', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalController>();

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const GoalsHeader(),
            const OfflineIndicator(),

            // Error state banner
            if (controller.errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                      tooltip: 'Tutup pesan error',
                      onPressed: () => controller.clearError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Goals Progress Summary
            ProgressSummary(
              key: const ValueKey('progress_summary'),
              initialGoals: _goals,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  controller.clearError();
                  await _loadGoals();
                },
                child: GoalsList(
                  key: const ValueKey('goals_list'),
                  initialGoals: _goals,
                  onGoalsChanged: () => _loadGoals(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goals_fab',
        onPressed: () => _showAddGoalModal(context),
        backgroundColor: DesignTokens.primaryColor,
        tooltip: 'Tambah Tujuan',
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  void _showAddGoalModal(BuildContext context) async {
    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: DesignTokens.backgroundDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return const AddGoalModal();
        },
      );

      if (result == true && mounted) {
        await _loadGoals();
      }
    } catch (e) {
      if (mounted) {
        _loadGoals();
      }
    }
  }
}
