import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/widgets/budgets/add_budget_modal.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/common/shimmer_loading.dart';
import 'package:financial_app/widgets/common/empty_state.dart';
import 'package:financial_app/utils/page_transitions.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _activeOnly = true;

  List<Map<String, dynamic>> _budgets = [];
  Map<String, String> _categories = {};
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final results = await Future.wait([
        _apiService.getCategories(),
        _apiService.getBudgets(activeOnly: _activeOnly),
        _apiService.getBudgetsSummary(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      final categories = results[0] as List<dynamic>;
      final budgets = results[1] as List<dynamic>;
      final summary = results[2] as Map<String, dynamic>;

      final categoryMap = <String, String>{};
      for (final cat in categories) {
        // Support both old and new field names
        final id = cat['category_id_232143'] ?? cat['id'];
        final name = cat['name_232143'] ?? cat['name'];
        final type = cat['type_232143'] ?? cat['type'];
        // Only include expense categories for budgets
        if (id != null &&
            name != null &&
            type?.toString().toLowerCase() == 'expense') {
          categoryMap[id.toString()] = name.toString();
        }
      }

      if (!mounted) return;

      LoggerService.debug('Filtered expense categories: ${categoryMap.length}');

      setState(() {
        _categories = categoryMap;
        _budgets = budgets.map((b) => b as Map<String, dynamic>).toList();
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('Error loading budgets', error: e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorHandlerService.getUserFriendlyMessage(e);
      });
      if (context.mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          _errorMessage!,
          onRetry: _loadData,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF8B5FBF),
                backgroundColor: const Color(0xFF1A1A1A),
                onRefresh: _loadData,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'budgets_fab',
        backgroundColor: const Color(0xFF8B5FBF),
        onPressed: _showAddBudgetModal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 8)),
              Text(
                AppLocalizations.of(context)!.budget,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: ResponsiveHelper.fontSize(context, 20),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _activeOnly
                    ? AppLocalizations.of(context)!.active
                    : AppLocalizations.of(context)!.all,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: ResponsiveHelper.fontSize(context, 12),
                ),
              ),
              Switch(
                value: _activeOnly,
                activeColor: const Color(0xFF8B5FBF),
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[800],
                onChanged: (value) {
                  setState(() {
                    _activeOnly = value;
                  });
                  _loadData();
                },
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
          if (_summary != null) _buildSummaryRow(context),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    // Support both old and new field names
    final totalBudget =
        (_summary?['total_amount'] ?? _summary?['total_budget'] as num?)
            ?.toDouble() ??
        0.0;
    final totalSpent = (_summary?['total_spent'] as num?)?.toDouble() ?? 0.0;
    final totalRemaining =
        (_summary?['total_remaining'] as num?)?.toDouble() ?? 0.0;

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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 12),
          ),
          border: Border.all(color: Colors.grey[800]!),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const CardListShimmer(itemCount: 5, cardHeight: 150);
    }

    if (_errorMessage != null) {
      return EmptyStates.serverError(_loadData, context);
    }

    if (_budgets.isEmpty) {
      return EmptyStates.noBudgets(_showAddBudgetModal, context);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: ResponsiveHelper.symmetricPadding(
        context,
        horizontal: 16,
        vertical: 8,
      ),
      itemCount: _budgets.length,
      itemBuilder: (context, index) {
        final budget = _budgets[index];
        return StaggeredListAnimation(
          index: index,
          child: _buildBudgetItem(context, budget),
        );
      },
    );
  }

  Widget _buildBudgetItem(BuildContext context, Map<String, dynamic> budget) {
    // Support both old and new field names
    final categoryId =
        (budget['category_id_232143'] ?? budget['category_id'])?.toString();
    final category =
        categoryId != null && _categories.containsKey(categoryId)
            ? _categories[categoryId]!
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

    return InkWell(
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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 16),
          ),
          border: Border.all(
            color:
                isOverBudget ? Colors.red.withOpacity(0.4) : Colors.grey[800]!,
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
                          color: displayColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.borderRadius(context, 8),
                          ),
                          border: Border.all(
                            color: displayColor.withOpacity(0.3),
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
                        width: ResponsiveHelper.horizontalSpacing(context, 10),
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
                          width: ResponsiveHelper.horizontalSpacing(context, 8),
                        ),
                        Container(
                          padding: ResponsiveHelper.symmetricPadding(
                            context,
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
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
        return const Color(0xFF8B5FBF);
    }
  }

  Future<void> _showAddBudgetModal() async {
    await _openBudgetModal();
  }

  Future<void> _openBudgetModal([Map<String, dynamic>? budget]) async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return AddBudgetModal(categories: _categories, initialBudget: budget);
      },
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _confirmDeleteBudget(Map<String, dynamic> budget) async {
    // Support both old and new field names
    final id = (budget['budget_id_232143'] ?? budget['id'])?.toString();
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
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
      try {
        await _apiService.deleteBudget(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.budget_deleted_successfully,
            ),
            backgroundColor: const Color(0xFF8B5FBF),
          ),
        );
        await _loadData();
      } catch (e) {
        LoggerService.error('Error deleting budget', error: e);
        if (!mounted) return;
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: () async {
            try {
              await _apiService.deleteBudget(id);
              if (!mounted) return;
              if (context.mounted) {
                ErrorHandlerService.showSuccessSnackbar(
                  context,
                  'Budget berhasil dihapus.',
                );
              }
              await _loadData();
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
