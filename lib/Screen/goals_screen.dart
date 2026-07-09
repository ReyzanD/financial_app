import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/widgets/goals/goals_header.dart';
import 'package:financial_app/widgets/goals/progress_summary.dart';
import 'package:financial_app/widgets/goals/goals_list.dart';
import 'package:financial_app/widgets/goals/add_goal_modal.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  // Use a simple refresh key that changes to rebuild widgets
  int _refreshKey = 0;
  String? _errorMessage;

  void _refreshGoals() {
    setState(() {
      _refreshKey++;
      _errorMessage = null;
    });
  }

  void _handleError(dynamic error) {
    LoggerService.error('GoalsScreen error', error: error);
    if (mounted) {
      ErrorHandlerService.showErrorSnackbar(
        context,
        ErrorHandlerService.getUserFriendlyMessage(error),
      );
    }
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
            const OfflineIndicator(),

            // Error state banner
            if (_errorMessage != null)
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
                        _errorMessage!,
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
                      onPressed: () => setState(() => _errorMessage = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Goals Progress Summary
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _errorMessage = null);
                  _refreshGoals();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      ProgressSummary(key: ValueKey('progress_$_refreshKey')),

                      // Goals List
                      GoalsList(
                        key: ValueKey('goals_$_refreshKey'),
                        onGoalsChanged: _refreshGoals,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'goals_fab',
        onPressed: _showAddGoalModal,
        backgroundColor: const Color(0xFF8B5FBF),
        tooltip: 'Tambah Tujuan',
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  void _showAddGoalModal() async {
    try {
      final result = await showModalBottomSheet<bool>(
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
    } catch (e) {
      _handleError(e);
    }
  }
}
