import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/features/goals/presentation/controllers/goal_controller.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/goals/goals_header.dart';
import 'package:financial_app/widgets/goals/progress_summary.dart';
import 'package:financial_app/widgets/goals/goals_list.dart';
import 'package:financial_app/widgets/goals/add_goal_modal.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    // Defer data load to next frame so the controller is available from Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GoalController>().loadData();
      }
    });
  }

  List<Map<String, dynamic>> _goalsFromEntities(GoalController ctrl) {
    return ctrl.goals.map((g) => g.toJson()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalController>();
    final l10n = AppLocalizations.of(context);
    final goalsMaps = _goalsFromEntities(controller);

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const GoalsHeader(),
            const OfflineIndicator(),

            // Loading indicator
            if (controller.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Error state banner
            if (!controller.isLoading && controller.errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
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
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          controller.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                      tooltip: l10n?.close_error_message ?? 'Tutup pesan error',
                      onPressed: () => controller.clearError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

            // Goals Progress Summary — uses controller.summary directly
            ProgressSummary(
              key: const ValueKey('progress_summary'),
              initialGoals: goalsMaps,
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  controller.clearError();
                  await controller.refresh();
                },
                child: GoalsList(
                  key: const ValueKey('goals_list'),
                  initialGoals: goalsMaps,
                  onGoalsChanged: () => controller.refresh(),
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
        tooltip: l10n?.add_target ?? 'Tambah Tujuan',
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  void _showAddGoalModal(BuildContext context) async {
    final ctrl = context.read<GoalController>();
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
        await ctrl.refresh();
      }
    } catch (e) {
      LoggerService.error('Error in goal modal', error: e);
      if (mounted) {
        await ctrl.refresh();
      }
    }
  }
}
