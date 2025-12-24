import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/widgets/goals/goals_helpers.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/goals/add_goal_modal.dart';
import 'package:financial_app/widgets/goals/contribute_modal.dart';
import 'package:financial_app/utils/responsive_helper.dart';

class GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final VoidCallback? onUpdated;

  const GoalCard({super.key, required this.goal, this.onUpdated});

  @override
  Widget build(BuildContext context) {
    final target = (goal['target'] as num).toDouble();
    final saved = (goal['saved'] as num).toDouble();
    final progress = target > 0 ? saved / target : 0.0;
    final deadline = goal['deadline'] as String?;
    final type = goal['type'] as String;

    // Handle priority - can be int or String from backend
    final priorityValue = goal['priority'];
    final priority =
        priorityValue is int
            ? priorityValue
            : (priorityValue is String ? int.tryParse(priorityValue) ?? 3 : 3);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.verticalSpacing(context, 12),
      ),
      padding: ResponsiveHelper.padding(context),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 16),
        ),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: ResponsiveHelper.iconSize(context, 40),
                height: ResponsiveHelper.iconSize(context, 40),
                decoration: BoxDecoration(
                  color: getGoalTypeColor(type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.borderRadius(context, 10),
                  ),
                ),
                child: Icon(
                  getGoalTypeIcon(type),
                  color: getGoalTypeColor(type),
                  size: ResponsiveHelper.iconSize(context, 20),
                ),
              ),
              SizedBox(
                width: ResponsiveHelper.horizontalSpacing(context, 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['name'] as String,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.fontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Target: Rp ${target.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: ResponsiveHelper.fontSize(context, 12),
                      ),
                    ),
                  ],
                ),
              ),
              _buildPriorityBadge(context, priority),
            ],
          ),

          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),

          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            color: getGoalTypeColor(type),
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.borderRadius(context, 10),
            ),
            minHeight: ResponsiveHelper.verticalSpacing(context, 8),
          ),

          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),

          // Progress Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${saved.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: ResponsiveHelper.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: ResponsiveHelper.fontSize(context, 12),
                ),
              ),
              if (deadline != null)
                Text(
                  formatDeadline(deadline),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: ResponsiveHelper.fontSize(context, 12),
                  ),
                ),
            ],
          ),

          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Iconsax.wallet_add,
                  label: 'Tambah Dana',
                  color: const Color(0xFF8B5FBF),
                  onTap: () => _showContributeDialog(context),
                ),
              ),
              SizedBox(
                width: ResponsiveHelper.horizontalSpacing(context, 8),
              ),
              _buildIconButton(
                context,
                icon: Iconsax.edit,
                color: Colors.blue,
                onTap: () => _showEditDialog(context),
              ),
              SizedBox(
                width: ResponsiveHelper.horizontalSpacing(context, 8),
              ),
              _buildIconButton(
                context,
                icon: Iconsax.trash,
                color: Colors.red,
                onTap: () => _showDeleteDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.borderRadius(context, 8),
      ),
      child: Container(
        padding: ResponsiveHelper.verticalPadding(context, multiplier: 0.5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 8),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveHelper.iconSize(context, 16),
            ),
            SizedBox(
              width: ResponsiveHelper.horizontalSpacing(context, 6),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: ResponsiveHelper.fontSize(context, 12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.borderRadius(context, 8),
      ),
      child: Container(
        padding: ResponsiveHelper.padding(context, multiplier: 0.5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 8),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          color: color,
          size: ResponsiveHelper.iconSize(context, 16),
        ),
      ),
    );
  }

  void _showContributeDialog(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ContributeModal(goal: goal);
      },
    );

    // Refresh if contribution was successful
    if (result == true) {
      onUpdated?.call();
    }
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddGoalModal(initialGoal: goal);
      },
    ).then((result) {
      if (result == true) {
        onUpdated?.call();
      }
    });
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            'Hapus Goal?',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${goal['name']}"?',
            style: GoogleFonts.poppins(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final apiService = ApiService();
                  await apiService.deleteGoal(goal['id']);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      ErrorHandlerService.showSuccessSnackbar(
                        context,
                        'Goal berhasil dihapus',
                      );
                    }
                    onUpdated?.call();
                  }
                } catch (e) {
                  LoggerService.error('Error deleting goal', error: e);
                  if (dialogContext.mounted) {
                    if (context.mounted) {
                      ErrorHandlerService.showErrorSnackbar(
                        context,
                        ErrorHandlerService.getUserFriendlyMessage(e),
                      );
                    }
                  }
                }
              },
              child: Text(
                'Hapus',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPriorityBadge(BuildContext context, int priority) {
    Color color;
    String text;

    // Priority: 5=Very High, 4=High, 3=Medium, 2=Low, 1=Very Low
    switch (priority) {
      case 5:
        color = Colors.red;
        text = 'Sangat Tinggi';
        break;
      case 4:
        color = Colors.orange;
        text = 'Tinggi';
        break;
      case 3:
        color = Colors.blue;
        text = 'Sedang';
        break;
      case 2:
        color = Colors.green;
        text = 'Rendah';
        break;
      case 1:
        color = Colors.grey;
        text = 'Sangat Rendah';
        break;
      default:
        color = Colors.blue;
        text = 'Sedang';
    }

    return Container(
      padding: ResponsiveHelper.symmetricPadding(
        context,
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 8),
        ),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: ResponsiveHelper.fontSize(context, 10),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
