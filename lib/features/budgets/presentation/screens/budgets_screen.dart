import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/budget_predictor.dart';
import 'package:financial_app/widgets/budgets/add_budget_modal.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/common/shimmer_loading.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/utils/page_transitions.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/budgets/presentation/controllers/budget_controller.dart';
import 'package:financial_app/models/budget_model.dart';
import 'package:financial_app/utils/design_tokens.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetController>(
      builder: (context, controller, child) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          backgroundColor: DesignTokens.backgroundDark,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, controller),
                const OfflineIndicator(),
                Expanded(
                  child: RefreshIndicator(
                    color: DesignTokens.primaryColor,
                    backgroundColor: DesignTokens.surfaceDark,
                    onRefresh: () => controller.refresh(),
                    child: _buildBody(controller),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'budgets_fab',
            backgroundColor: DesignTokens.primaryColor,
            onPressed: _showAddBudgetModal,
            tooltip: l10n?.add_budget ?? 'Tambah Anggaran',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BudgetController ctrl) {
    final controller = ctrl;
    return Container(
      padding: ResponsiveHelper.symmetricPadding(
        context,
        horizontal: 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.arrow_left, color: Colors.white),
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
              Semantics(
                header: true,
                child: Text(
                  AppLocalizations.of(context)!.budget,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.fontSize(context, 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                controller.activeOnly
                    ? AppLocalizations.of(context)!.active
                    : AppLocalizations.of(context)!.all,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: ResponsiveHelper.fontSize(context, 12),
                ),
              ),
              Switch(
                value: controller.activeOnly,
                activeThumbColor: DesignTokens.primaryColor,
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[800],
                onChanged: (value) {
                  controller.toggleActiveFilter();
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.auto_awesome,
                  color: DesignTokens.primaryColor,
                ),
                onPressed: _showSmartBudgetSuggestions,
                tooltip: 'Saran Budget AI',
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          _buildSummaryRow(context, controller.summary),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, Map<String, dynamic> summary) {
    final totalBudget = (summary['total_budgeted'] as num?)?.toDouble() ?? 0.0;
    final totalSpent = (summary['total_spent'] as num?)?.toDouble() ?? 0.0;
    final totalRemaining = (summary['remaining'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        _buildSummaryChip(
          context,
          AppLocalizations.of(context)!.total_budget,
          totalBudget,
        ),
        SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
        _buildSummaryChip(
          context,
          AppLocalizations.of(context)!.spent,
          totalSpent,
        ),
        SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
        _buildSummaryChip(
          context,
          AppLocalizations.of(context)!.remaining,
          totalRemaining,
        ),
      ],
    );
  }

  Widget _buildSummaryChip(BuildContext context, String label, double amount) {
    return Expanded(
      child: Container(
        padding: ResponsiveHelper.symmetricPadding(
          context,
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 12),
          ),
          border: Border.all(color: DesignTokens.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: ResponsiveHelper.fontSize(context, 11),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
            Text(
              CurrencyFormatter.formatRupiah(amount.toInt()),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: ResponsiveHelper.fontSize(context, 13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BudgetController controller) {
    if (controller.isLoading) {
      return const CardListShimmer(itemCount: 5, cardHeight: 150);
    }

    if (controller.error != null) {
      return EmptyStates.serverError(() => controller.refresh(), context);
    }

    if (controller.budgets.isEmpty) {
      return EmptyStates.noBudgets(_showAddBudgetModal, context);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: ResponsiveHelper.symmetricPadding(
        context,
        horizontal: 16,
        vertical: 8,
      ),
      itemCount: controller.budgets.length,
      itemBuilder: (context, index) {
        final budget = controller.budgets[index];
        return StaggeredListAnimation(
          index: index,
          child: _buildBudgetItem(context, budget, controller.categories),
        );
      },
    );
  }

  /// Convert BudgetModel to the Map format expected by existing UI code.
  Map<String, dynamic> _budgetToMap(BudgetModel b) {
    return {
      'budget_id_232143': b.id,
      'category_id_232143': b.categoryId,
      'amount_232143': b.amount,
      'spent_amount_232143': b.spent,
      'period_start_232143': b.periodStart.toIso8601String(),
      'period_end_232143': b.periodEnd.toIso8601String(),
      'is_active_232143': b.isActive ? 1 : 0,
      'period_232143':
          '${b.periodStart.day}/${b.periodStart.month} - ${b.periodEnd.day}/${b.periodEnd.month}',
      // Non-suffixed fallbacks for legacy code paths
      'id': b.id,
      'category_id': b.categoryId,
      'amount': b.amount,
      'spent': b.spent,
      'is_active': b.isActive,
    };
  }

  Widget _buildBudgetItem(
    BuildContext context,
    BudgetModel budgetEntity,
    Map<String, String> categories,
  ) {
    final budget = _budgetToMap(budgetEntity);
    final categoryId =
        (budget['category_id_232143'] ?? budget['category_id'])?.toString();
    final category =
        categoryId != null && categories.containsKey(categoryId)
            ? categories[categoryId]!
            : AppLocalizations.of(context)!.all_categories;

    final amount =
        (budget['amount_232143'] ?? budget['amount'] as num?)?.toDouble() ??
        0.0;
    final spent =
        (budget['spent_amount_232143'] ?? budget['spent'] as num?)
            ?.toDouble() ??
        0.0;
    final remaining = amount - spent;
    final period =
        (budget['period_232143'] ?? budget['period'] as String?) ?? '-';
    // Handle is_active: in SQLite it's stored as int (0 or 1), not bool
    final isActiveValue = budget['is_active_232143'] ?? budget['is_active'];
    final isActive =
        isActiveValue is bool
            ? isActiveValue
            : (isActiveValue is int ? isActiveValue == 1 : true);

    final percentage = amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > amount && amount > 0;
    final color = _getCategoryColor(category);
    final displayColor = isOverBudget ? Colors.red : color;

    return Semantics(
      label: "Anggaran ${budget['category'] ?? ''}",
      button: true,
      child: InkWell(
        onTap: () {
          _openBudgetModal(budget);
        },
        onLongPress: () {
          _confirmDeleteBudget(budget);
        },
        child: Container(
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
            border: Border.all(
              color:
                  isOverBudget
                      ? Colors.red.withValues(alpha: 0.4)
                      : DesignTokens.borderDark,
              width: isOverBudget ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: ResponsiveHelper.padding(
                            context,
                            multiplier: 0.375,
                          ),
                          decoration: BoxDecoration(
                            color: displayColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.borderRadius(context, 8),
                            ),
                            border: Border.all(
                              color: displayColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: displayColor,
                            size: ResponsiveHelper.iconSize(context, 16),
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveHelper.horizontalSpacing(
                            context,
                            10,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: ResponsiveHelper.fontSize(context, 14),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOverBudget) ...[
                          SizedBox(
                            width: ResponsiveHelper.horizontalSpacing(
                              context,
                              8,
                            ),
                          ),
                          Container(
                            padding: ResponsiveHelper.symmetricPadding(
                              context,
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                ResponsiveHelper.borderRadius(context, 8),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red,
                                  size: ResponsiveHelper.iconSize(context, 14),
                                ),
                                SizedBox(
                                  width: ResponsiveHelper.horizontalSpacing(
                                    context,
                                    4,
                                  ),
                                ),
                                Text(
                                  AppLocalizations.of(context)!.over,
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontSize: ResponsiveHelper.fontSize(
                                      context,
                                      10,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.formatRupiah(spent.toInt()),
                        style: GoogleFonts.poppins(
                          color: displayColor,
                          fontSize: ResponsiveHelper.fontSize(context, 13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'dari ${CurrencyFormatter.formatRupiah(amount.toInt())}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: ResponsiveHelper.fontSize(context, 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Periode: $period',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: ResponsiveHelper.fontSize(context, 11),
                    ),
                  ),
                  if (!isActive)
                    Container(
                      padding: ResponsiveHelper.symmetricPadding(
                        context,
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.borderRadius(context, 12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.inactive,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[300],
                          fontSize: ResponsiveHelper.fontSize(context, 10),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.borderRadius(context, 10),
                ),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[850],
                  valueColor: AlwaysStoppedAnimation(displayColor),
                  minHeight: ResponsiveHelper.verticalSpacing(context, 8),
                ),
              ),
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOverBudget
                        ? 'Melebihi ${CurrencyFormatter.formatRupiah((spent - amount).toInt())}'
                        : 'Sisa ${CurrencyFormatter.formatRupiah(remaining.toInt())}',
                    style: GoogleFonts.poppins(
                      color: isOverBudget ? Colors.red[300] : Colors.green[300],
                      fontSize: ResponsiveHelper.fontSize(context, 11),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      color: displayColor,
                      fontSize: ResponsiveHelper.fontSize(context, 12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'makanan':
        return const Color(0xFFE74C3C);
      case 'transportasi':
        return const Color(0xFFF39C12);
      case 'hiburan':
        return const Color(0xFF9B59B6);
      default:
        return DesignTokens.primaryColor;
    }
  }

  Future<void> _showSmartBudgetSuggestions() async {
    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryColor,
              ),
            ),
      );

      final predictor = BudgetPredictor();
      final suggestedBudgets = await predictor.suggestOptimalBudgets();
      final risks = await predictor.assessOverspendingRisk();

      if (!mounted) return;
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder:
                  (context, scrollController) => Container(
                    decoration: const BoxDecoration(
                      color: DesignTokens.surfaceDark,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: ListView(
                      controller: scrollController,
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
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: DesignTokens.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saran Budget Optimal',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Berdasarkan rata-rata pengeluaran 3 bulan terakhir + buffer 10%',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (suggestedBudgets.isNotEmpty) ...[
                          ...suggestedBudgets.entries.map(
                            (e) => _buildSuggestionItem(e.key, e.value),
                          ),
                        ] else
                          Center(
                            child: Text(
                              l10n?.no_data_for_recommendation ??
                                  'Belum ada data untuk rekomendasi',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        if (risks.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n?.budget_warning ?? 'Peringatan Budget',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...risks
                              .where(
                                (r) =>
                                    r['risk_level'] == 'critical' ||
                                    r['risk_level'] == 'high',
                              )
                              .map((risk) => _buildRiskItem(risk)),
                        ],
                      ],
                    ),
                  ),
            ),
      );
    } catch (e) {
      if (mounted) {
        final msg = AppLocalizations.of(context)?.failed_to_load_budget_suggestions ??
            'Gagal memuat saran budget';
        Navigator.pop(context);
        ErrorHandlerService.showErrorSnackbar(context, msg);
      }
    }
  }

  Widget _buildSuggestionItem(String category, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            CurrencyFormatter.formatRupiah(amount.toInt()),
            style: GoogleFonts.poppins(
              color: DesignTokens.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(Map<String, dynamic> risk) {
    final category = risk['category_name'] as String? ?? 'Tidak Diketahui';
    final usagePercent = (risk['usage_percent'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = risk['risk_level'] as String? ?? 'unknown';
    final remaining = (risk['remaining'] as num?)?.toDouble() ?? 0.0;

    final color =
        riskLevel == 'critical' ? Colors.red[400] : Colors.orange[400];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Text(
                  '${usagePercent.toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Sisa: ${CurrencyFormatter.formatRupiah(remaining.toInt())}',
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBudgetModal() async {
    await _openBudgetModal();
  }

  Future<void> _openBudgetModal([Map<String, dynamic>? budget]) async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final ctrl = context.read<BudgetController>();
        return AddBudgetModal(
          categories: ctrl.categories,
          initialBudget: budget,
        );
      },
    );
    if (result == true && mounted) {
      final ctrl = context.read<BudgetController>();
      ctrl.refresh();
    }
  }

  Future<void> _confirmDeleteBudget(Map<String, dynamic> budget) async {
    final l10n = AppLocalizations.of(context);
    final id = (budget['budget_id_232143'] ?? budget['id'])?.toString();
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DesignTokens.surfaceDark,
          title: Text(
            AppLocalizations.of(context)!.delete_budget,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.confirm_delete_budget,
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final ctrl = context.read<BudgetController>();
      try {
        await ctrl.deleteBudget(id);
        if (!mounted) return;
        ErrorHandlerService.showSuccessSnackbar(
          context,
          AppLocalizations.of(context)!.budget_deleted_successfully,
        );
      } catch (e) {
        LoggerService.error('Error deleting budget', error: e);
        if (!mounted) return;
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: () async {
            try {
              await ctrl.deleteBudget(id);
              if (!mounted) return;
              if (context.mounted) {
                ErrorHandlerService.showSuccessSnackbar(
                  context,
                  l10n?.budget_deleted ?? 'Budget berhasil dihapus.',
                );
              }
            } catch (retryError) {
              LoggerService.error(
                'Error retrying delete budget',
                error: retryError,
              );
            }
          },
        );
      }
    }
  }
}
