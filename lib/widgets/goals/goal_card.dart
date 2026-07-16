import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/widgets/goals/goals_helpers.dart';
import 'package:financial_app/services/data/goal_data_service.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/goals/add_goal_modal.dart';
import 'package:financial_app/widgets/goals/contribute_modal.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class GoalCard extends StatefulWidget {
  final Map<String, dynamic> goal;
  final VoidCallback? onUpdated;

  const GoalCard({super.key, required this.goal, this.onUpdated});

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  List<Map<String, dynamic>> _contributions = [];

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    final goalId =
        (widget.goal['goal_id_232143'] ?? widget.goal['id']).toString();
    if (goalId.isEmpty) return;
    try {
      final accountService = getIt<AccountService>();
      final contribs = await accountService.getGoalContributions(goalId);
      if (mounted) setState(() => _contributions = contribs);
    } catch (e) {
      LoggerService.error('Error loading contributions', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goal = widget.goal;
    final targetAmount = goal['target_amount_232143'] ?? goal['target'];
    final currentAmount = goal['current_amount_232143'] ?? goal['saved'];
    final target = (targetAmount as num?)?.toDouble() ?? 0.0;
    final saved = (currentAmount as num?)?.toDouble() ?? 0.0;
    final progress = target > 0 ? saved / target : 0.0;
    final deadline = goal['target_date_232143'] ?? goal['deadline'];
    final type = goal['goal_type_232143'] ?? goal['type'] ?? 'other';

    final priorityValue = goal['priority_232143'] ?? goal['priority'];
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
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 16),
        ),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveHelper.iconSize(context, 40),
                height: ResponsiveHelper.iconSize(context, 40),
                decoration: BoxDecoration(
                  color: getGoalTypeColor(type).withValues(alpha: 0.2),
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
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['name_232143'] ?? goal['name'] ?? 'Unnamed Goal',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.fontSize(context, 16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Target: ${CurrencyFormatter.formatRupiah(target.toInt())}',
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
                CurrencyFormatter.formatRupiah(saved.toInt()),
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
              if (deadline != null && deadline.toString().isNotEmpty)
                Text(
                  formatDeadline(deadline.toString()),
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
                  label: l10n?.add_fund ?? 'Tambah Dana',
                  color: DesignTokens.primaryColor,
                  onTap: () => _showContributeDialog(context),
                ),
              ),
              if (_contributions.isNotEmpty) ...[
                SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
                _buildIconButton(
                  context,
                  icon: Iconsax.clock,
                  color: Colors.amber,
                  onTap: () => _showContributionsDialog(context),
                ),
              ],
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
              _buildIconButton(
                context,
                icon: Iconsax.edit,
                color: Colors.blue,
                onTap: () => _showEditDialog(context),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
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

  void _showContributionsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goal = widget.goal;
    final goalName = goal['name_232143'] ?? goal['name'] ?? 'Goal';

    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.contribution_history ?? 'Riwayat Kontribusi',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                goalName,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              if (_contributions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      l10n?.no_contributions_yet ?? 'Belum ada kontribusi',
                      style: GoogleFonts.poppins(color: Colors.grey[500]),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _contributions.length,
                    separatorBuilder:
                        (_, __) => Divider(color: DesignTokens.borderDark),
                    itemBuilder: (_, i) {
                      final c = _contributions[i];
                      final amt =
                          (c['amount_232143'] as num?)?.toDouble() ?? 0.0;
                      final acctName = c['account_name']?.toString();
                      final date = c['contributed_at_232143']?.toString() ?? '';
                      final note = c['note_232143']?.toString();

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryColor.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.money_4,
                            color: DesignTokens.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          CurrencyFormatter.formatRupiah(amt.toInt()),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${acctName ?? 'Tanpa akun'}${note != null ? ' - $note' : ''}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        trailing: Text(
                          _formatDate(date),
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date.length >= 10 ? date.substring(0, 10) : date;
    }
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 8),
          ),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: ResponsiveHelper.iconSize(context, 16),
            ),
            SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 6)),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 8),
          ),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ContributeModal(goal: widget.goal);
      },
    );
    if (result == true) {
      _loadContributions();
      widget.onUpdated?.call();
    }
  }

  void _showEditDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddGoalModal(initialGoal: widget.goal);
      },
    ).then((result) {
      if (result == true) widget.onUpdated?.call();
    });
  }

  void _showDeleteDialog(BuildContext context) {
    final goalName =
        widget.goal['name_232143'] ?? widget.goal['name'] ?? 'Goal';
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: DesignTokens.surfaceDark,
          title: Text(
            l10n?.delete_goal_confirm ?? 'Hapus Goal?',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: Text(
            '${l10n?.delete_goal_message ?? 'Apakah Anda yakin ingin menghapus'} "$goalName"?',
            style: GoogleFonts.poppins(color: Colors.grey[400]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n?.cancel ?? 'Batal',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final goalService = getIt<GoalDataService>();
                  await goalService.deleteGoal(
                    widget.goal['goal_id_232143'] ?? widget.goal['id'],
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    if (context.mounted) {
                      ErrorHandlerService.showSuccessSnackbar(
                        context,
                        l10n?.goal_deleted_successfully ??
                            'Goal berhasil dihapus',
                      );
                    }
                    widget.onUpdated?.call();
                  }
                } catch (e) {
                  LoggerService.error('Error deleting goal', error: e);
                  if (dialogContext.mounted && context.mounted) {
                    ErrorHandlerService.showErrorSnackbar(
                      context,
                      ErrorHandlerService.getUserFriendlyMessage(e),
                    );
                  }
                }
              },
              child: Text(
                l10n?.delete ?? 'Hapus',
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 8),
        ),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
