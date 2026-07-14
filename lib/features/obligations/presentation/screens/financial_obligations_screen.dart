import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/obligations/obligation_view_tabs.dart';
import 'package:financial_app/widgets/obligations/all_obligations_view.dart';
import 'package:financial_app/widgets/obligations/upcoming_obligations_view.dart';
import 'package:financial_app/widgets/obligations/debts_view.dart';
import 'package:financial_app/widgets/obligations/subscriptions_view.dart';
import 'package:financial_app/widgets/obligations/overdue_obligations_view.dart';
import 'package:financial_app/widgets/obligations/obligation_helpers.dart';
import 'package:financial_app/widgets/obligations/obligation_filters.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/widgets/common/responsive_content.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/features/obligations/presentation/controllers/obligation_controller.dart';

class FinancialObligationsScreen extends StatefulWidget {
  final String initialTab;

  const FinancialObligationsScreen({
    super.key,
    this.initialTab = 'all',
  });

  @override
  State<FinancialObligationsScreen> createState() =>
      _FinancialObligationsScreenState();
}

class _FinancialObligationsScreenState
    extends State<FinancialObligationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<ObligationController>();
      ctrl.loadSummary();
      if (widget.initialTab != 'all') {
        ctrl.setView(widget.initialTab);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        title: Text(
          l10n.financial_obligations,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<ObligationController>(
            builder:
                (context, ctrl, _) => IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Iconsax.filter, color: Colors.white),
                      // Note: filter status tracking removed since filters are now managed in the bottom sheet
                    ],
                  ),
                  tooltip: 'Filter',
                  onPressed: () => _showFiltersDialog(context),
                ),
          ),
        ],
      ),
      body: ResponsiveContent(
        child: Column(
          children: [
            const OfflineIndicator(),
          Consumer<ObligationController>(
            builder: (context, ctrl, _) => _buildSummaryCards(context, ctrl),
          ),
          // Search Bar
          Padding(
            padding: ResponsiveHelper.horizontalPadding(context),
            child: Consumer<ObligationController>(
              builder:
                  (context, ctrl, _) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: DesignTokens.borderDark.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: ctrl.searchController,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.search_obligations,
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Iconsax.search_normal,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                        ),
                        suffixIcon:
                            ctrl.searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: DesignTokens.borderDark.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                                  ),
                                  tooltip: l10n.delete_search,
                                  onPressed: ctrl.clearSearch,
                                )
                                : null,
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
          // View Selector
          Consumer<ObligationController>(
            builder:
                (context, ctrl, _) => ObligationViewTabs(
                  selectedView: ctrl.selectedView,
                  onViewChanged: (value) => ctrl.setView(value),
                ),
          ),
          // Content based on selected view
          Expanded(
            child: Consumer<ObligationController>(
              builder: (context, ctrl, _) => _buildSelectedView(ctrl),
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [DesignTokens.primaryColor, Color(0xFF6B4C93)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'obligations_fab',
          tooltip: l10n.add_obligation,
          onPressed: () async {
            final result = await ObligationHelpers.showAddObligationModal(
              context,
            );
            if (result == true) {
              await context.read<ObligationController>().refresh();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Iconsax.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ObligationController ctrl) {
    final l10n = AppLocalizations.of(context)!;

    if (ctrl.summaryLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryColor),
        ),
      );
    }

    if (ctrl.summaryError != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            ErrorHandlerService.getUserFriendlyMessage(ctrl.summaryError),
            style: GoogleFonts.poppins(color: Colors.red[300], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final summary = ctrl.summary;
    if (summary.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.setView('all'),
                  child: _buildSummaryCard(
                    l10n.monthly_total,
                    CurrencyFormatter.formatRupiah(
                      summary['monthlyTotal'] ?? 0,
                    ),
                    Colors.blue,
                    Iconsax.calendar,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.setView('debts'),
                  child: _buildSummaryCard(
                    l10n.total_debt,
                    CurrencyFormatter.formatRupiah(summary['totalDebt'] ?? 0),
                    Colors.red,
                    Iconsax.card,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.setView('upcoming'),
                  child: _buildSummaryCard(
                    l10n.due_this_week,
                    '${summary['dueThisWeek'] ?? 0} ${l10n.obligations_count}',
                    Colors.orange,
                    Iconsax.clock,
                    isCount: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.setView('overdue'),
                  child: _buildSummaryCard(
                    l10n.overdue_count,
                    '${summary['overdue'] ?? 0} ${l10n.obligations_count}',
                    Colors.red,
                    Iconsax.warning_2,
                    isCount: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    Color color,
    IconData icon, {
    bool isCount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1F1F1F), DesignTokens.surfaceDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (isCount && amount.split(' ')[0] != '0')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    border: Border.all(
                      color: color.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    amount.split(' ')[0],
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isCount ? 15 : 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedView(ObligationController ctrl) {
    final key = ValueKey('${ctrl.selectedView}_${ctrl.refreshKey}');
    final filters = ctrl.filters;
    switch (ctrl.selectedView) {
      case 'all':
        return AllObligationsView(
          key: key,
          searchQuery: ctrl.searchQuery,
          filters: filters,
        );
      case 'upcoming':
        return UpcomingObligationsView(
          key: key,
          searchQuery: ctrl.searchQuery,
          filters: filters,
        );
      case 'overdue':
        return OverdueObligationsView(
          key: key,
          searchQuery: ctrl.searchQuery,
          filters: filters,
        );
      case 'debts':
        return DebtsView(
          key: key,
          searchQuery: ctrl.searchQuery,
          filters: filters,
        );
      case 'subscriptions':
        return SubscriptionsView(
          key: key,
          searchQuery: ctrl.searchQuery,
          filters: filters,
        );
      default:
        return AllObligationsView(
          key: key,
          searchQuery: ctrl.searchQuery,
          filters: filters,
        );
    }
  }

  void _showFiltersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ObligationFiltersWidget(
              initialFilters: context.read<ObligationController>().filters,
              onFiltersChanged: (filters) {
                context.read<ObligationController>().applyFilters(filters);
              },
            ),
          ),
    );
  }
}
