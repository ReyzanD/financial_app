import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:financial_app/services/financial_advisor_service.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/widgets/goals/add_goal_modal.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/core/di/service_locator.dart';

enum _AnalysisPeriod { currentMonth, lastMonth }

class FinancialAdvisorScreen extends StatefulWidget {
  const FinancialAdvisorScreen({super.key});

  @override
  State<FinancialAdvisorScreen> createState() => _FinancialAdvisorScreenState();
}

class _FinancialAdvisorScreenState extends State<FinancialAdvisorScreen> {
  final FinancialAdvisorService _service = getIt<FinancialAdvisorService>();
  FiftyThirtyTwentyAnalysis? _analysis;
  ZeroBasedAnalysis? _zeroBased;
  List<FiftyThirtyTwentyAnalysis>? _trendMonths;
  String? _errorMessage;
  bool _isLoading = true;
  _AnalysisPeriod _selectedPeriod = _AnalysisPeriod.currentMonth;
  BudgetingModel _selectedModel = BudgetingModel.fiftyThirtyTwenty;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final now = DateTime.now();
      late final FiftyThirtyTwentyAnalysis analysis;
      late final DateTime analysisStart;
      late final DateTime analysisEnd;

      switch (_selectedPeriod) {
        case _AnalysisPeriod.currentMonth:
          analysisStart = DateTime(now.year, now.month, 1);
          analysisEnd = DateTime(now.year, now.month + 1, 0);
        case _AnalysisPeriod.lastMonth:
          analysisStart = DateTime(now.year, now.month - 1, 1);
          analysisEnd = DateTime(now.year, now.month, 0);
      }

      analysis = await _service.analyzeForPeriod(
        start: analysisStart,
        end: analysisEnd,
      );

      // Load trend data (last 3 months) in parallel
      final trendMonths = await _service.analyzeMultiMonth(3);

      // Zero-based analysis for the same period (independent of 50/30/20)
      final zeroBased = await _service.analyzeZeroBasedForPeriod(
        start: analysisStart,
        end: analysisEnd,
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _zeroBased = zeroBased;
          _trendMonths = trendMonths;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.surfaceDark,
        title: Text(
          'Penasihat Keuangan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          _buildPeriodSelector(),
          _buildModelSelector(),
          Expanded(
            child:
                _isLoading
                    ? _buildLoading()
                    : _errorMessage != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: DesignTokens.surfaceDark,
      child: Row(
        children: [
          _periodChip(label: 'Bulan Ini', period: _AnalysisPeriod.currentMonth),
          const SizedBox(width: 8),
          _periodChip(label: 'Bulan Lalu', period: _AnalysisPeriod.lastMonth),
        ],
      ),
    );
  }

  Widget _periodChip({required String label, required _AnalysisPeriod period}) {
    final selected = _selectedPeriod == period;
    return Material(
      color:
          selected
              ? DesignTokens.primaryColor
              : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      child: InkWell(
        onTap: () {
          if (_selectedPeriod != period) {
            setState(() => _selectedPeriod = period);
            _loadAnalysis();
          }
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? Colors.white : DesignTokens.textSecondaryDark,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelSelector() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: DesignTokens.surfaceDark,
      child: Row(
        children: [
          _modelChip(
            label: l10n?.rule503020 ?? 'Aturan 50/30/20',
            model: BudgetingModel.fiftyThirtyTwenty,
          ),
          const SizedBox(width: 8),
          _modelChip(
            label: l10n?.zeroBasedBudget ?? 'Zero-Based',
            model: BudgetingModel.zeroBased,
          ),
        ],
      ),
    );
  }

  Widget _modelChip({required String label, required BudgetingModel model}) {
    final selected = _selectedModel == model;
    return Material(
      color:
          selected
              ? DesignTokens.primaryColor
              : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      child: InkWell(
        onTap: () {
          if (_selectedModel != model) {
            setState(() => _selectedModel = model);
          }
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? Colors.white : DesignTokens.textSecondaryDark,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryColor),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: Colors.redAccent),
            const SizedBox(height: DesignTokens.spacing4),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing6),
            Material(
              color: DesignTokens.primaryColor,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              child: InkWell(
                onTap: _loadAnalysis,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    'Coba Lagi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final a = _analysis!;
    if (a.monthlyIncome <= 0) {
      return _buildEmptyState();
    }
    final assessment = _service.getAssessment(a);

    return RefreshIndicator(
      onRefresh: _loadAnalysis,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Income / Expense summary
            _buildSummaryCard(a),
            const SizedBox(height: DesignTokens.spacing4),

            // Budgeting model breakdown
            if (_selectedModel == BudgetingModel.zeroBased &&
                _zeroBased != null)
              _buildZeroBasedCard(_zeroBased!)
            else
              _buildRuleCard(a),
            const SizedBox(height: DesignTokens.spacing4),

            // Trend (last 3 months)
            if (_trendMonths != null && _trendMonths!.length >= 2)
              _buildTrendSection(_trendMonths!),
            const SizedBox(height: DesignTokens.spacing4),

            // Assessment
            _buildAssessmentCard(assessment),
            const SizedBox(height: DesignTokens.spacing4),

            // Savings suggestions
            _buildSuggestionsSection(a),
            const SizedBox(height: DesignTokens.spacing4),

            // Needs breakdown
            if (a.needsCategories.isNotEmpty)
              _buildCategoryBreakdown(
                title: 'Kebutuhan (50%)',
                icon: Iconsax.shield_tick,
                color: Colors.blue,
                categories: a.needsCategories,
                total: a.needsActual,
                target: a.needsTarget,
                gap: a.needsGap,
              ),
            const SizedBox(height: DesignTokens.spacing3),

            // Wants breakdown
            if (a.wantsCategories.isNotEmpty)
              _buildCategoryBreakdown(
                title: 'Keinginan (30%)',
                icon: Iconsax.heart,
                color: Colors.orange,
                categories: a.wantsCategories,
                total: a.wantsActual,
                target: a.wantsTarget,
                gap: a.wantsGap,
              ),
            const SizedBox(height: DesignTokens.spacing3),

            // Goal run-rates
            if (a.goalRunRates.isNotEmpty) _buildGoalSection(a),
            const SizedBox(height: DesignTokens.spacing6),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.wallet,
              size: 64,
              color: DesignTokens.textSecondaryDark,
            ),
            const SizedBox(height: DesignTokens.spacing4),
            Text(
              'Belum Ada Data Bulan Ini',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              'Tambahkan transaksi pemasukan bulan ini\nuntuk melihat analisis 50/30/20.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Summary Card ───────────────────────────────────────────────
  Widget _buildSummaryCard(FiftyThirtyTwentyAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Bulan Ini',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing3),
          _summaryRow(
            Iconsax.arrow_up_2,
            'Pemasukan',
            CurrencyFormatter.formatRupiah(a.monthlyIncome),
            Colors.green,
          ),
          const SizedBox(height: 6),
          _summaryRow(
            Iconsax.arrow_down_2,
            'Pengeluaran',
            CurrencyFormatter.formatRupiah(a.monthlyExpense),
            Colors.red,
          ),
          const Divider(color: DesignTokens.borderDark, height: 20),
          _summaryRow(
            Iconsax.save_2,
            'Tabungan',
            CurrencyFormatter.formatRupiah(a.savings),
            a.savings >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ─── 50/30/20 Rule Card ─────────────────────────────────────────
  Widget _buildZeroBasedCard(ZeroBasedAnalysis z) {
    final l10n = AppLocalizations.of(context);
    final hasSurplus = z.unallocated >= 0;
    final unallocatedColor =
        hasSurplus ? DesignTokens.successColor : Colors.redAccent;
    final unallocatedLabel =
        hasSurplus
            ? (l10n?.zbSurplus ?? 'Surplus (belum dialokasikan)')
            : (l10n?.zbShortfall ?? 'Kekurangan (perlu ditutup)');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.diagram,
                color: DesignTokens.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.zeroBasedBudget ?? 'Anggaran Zero-Based',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing2),
          Text(
            l10n?.zbMathHint ??
                'Setiap pengeluaran dapat "pekerjaan"; sisa = pemasukan − total alokasi.',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing4),
          // The explicit math: income - expense = unallocated
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.backgroundDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Column(
              children: [
                _mathRow(
                  l10n?.income ?? 'Pemasukan',
                  CurrencyFormatter.formatRupiah(z.monthlyIncome),
                ),
                _mathRow(
                  l10n?.totalAllocated ?? 'Total dialokasikan',
                  CurrencyFormatter.formatRupiah(z.monthlyExpense),
                ),
                const Divider(color: DesignTokens.borderDark, height: 16),
                _mathRow(
                  unallocatedLabel,
                  CurrencyFormatter.formatRupiah(z.unallocated.abs()),
                  valueColor: unallocatedColor,
                  bold: true,
                ),
                const SizedBox(height: 4),
                Text(
                  '${z.allocatedPercent.toStringAsFixed(0)}% dari pemasukan dialokasikan',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spacing4),
          Text(
            l10n?.allocations ?? 'Alokasi per kategori',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing2),
          if (z.allocations.isEmpty)
            Text(
              l10n?.noAllocations ?? 'Belum ada pengeluaran tercatat.',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 12,
              ),
            )
          else
            ...z.allocations.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.formatRupiah(c.amount),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (c.percentOfIncome / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DesignTokens.primaryColor,
                      ),
                      minHeight: 4,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${c.percentOfIncome.toStringAsFixed(0)}% dari pemasukan',
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mathRow(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(FiftyThirtyTwentyAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.diagram,
                color: DesignTokens.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Aturan 50/30/20',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing4),
          _buildRuleBar(
            label: 'Kebutuhan',
            target: 50,
            actualPercent: a.needsPercent,
            actualAmount: a.needsActual,
            targetAmount: a.needsTarget,
            color: Colors.blue,
            icon: Iconsax.shield_tick,
            gap: a.needsGap,
          ),
          const SizedBox(height: DesignTokens.spacing3),
          _buildRuleBar(
            label: 'Keinginan',
            target: 30,
            actualPercent: a.wantsPercent,
            actualAmount: a.wantsActual,
            targetAmount: a.wantsTarget,
            color: Colors.orange,
            icon: Iconsax.heart,
            gap: a.wantsGap,
          ),
          const SizedBox(height: DesignTokens.spacing3),
          _buildRuleBar(
            label: 'Tabungan',
            target: 20,
            actualPercent: a.savingsPercent,
            actualAmount: a.savings,
            targetAmount: a.savingsTarget,
            color: Colors.green,
            icon: Iconsax.save_2,
            gap: a.savingsGap,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBar({
    required String label,
    required double target,
    required double actualPercent,
    required double actualAmount,
    required double targetAmount,
    required Color color,
    required IconData icon,
    required double gap,
  }) {
    final overTarget =
        (label == 'Tabungan') ? actualPercent < target : actualPercent > target;
    final pct = actualPercent.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '${actualPercent.toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                color: overTarget ? Colors.redAccent : Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
              overTarget ? Colors.redAccent : color,
            ),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing1),
        Row(
          children: [
            Text(
              'Aktual: ${CurrencyFormatter.formatRupiah(actualAmount)}',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Text(
              'Target $target%: ${CurrencyFormatter.formatRupiah(targetAmount)}',
              style: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Trend Section ────────────────────────────────────────────
  Widget _buildTrendSection(List<FiftyThirtyTwentyAnalysis> months) {
    final monthLabels = _buildMonthLabels(months.length);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.trend_up, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tren 3 Bulan',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing3),
          // Header row
          Row(
            children: [
              const SizedBox(width: 60),
              ...monthLabels.map(
                (label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textSecondaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing2),
          _trendRow(
            'Kebutuhan',
            Colors.blue,
            months.map((m) => m.needsPercent).toList(),
            50,
          ),
          const SizedBox(height: 6),
          _trendRow(
            'Keinginan',
            Colors.orange,
            months.map((m) => m.wantsPercent).toList(),
            30,
          ),
          const SizedBox(height: 6),
          _trendRow(
            'Tabungan',
            Colors.green,
            months.map((m) => m.savingsPercent).toList(),
            20,
          ),
        ],
      ),
    );
  }

  List<String> _buildMonthLabels(int count) {
    final now = DateTime.now();
    final labels = <String>[];
    for (int i = count - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      labels.add(_monthName(month.month));
    }
    return labels;
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return names[month - 1];
  }

  Widget _trendRow(
    String label,
    Color color,
    List<double> values,
    double target,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ...values.asMap().entries.map((entry) {
          final isLatest = entry.key == values.length - 1;
          final val = entry.value;
          final overTarget = val > target;
          return Expanded(
            child: Column(
              children: [
                Text(
                  val > 0 ? '${val.toStringAsFixed(0)}%' : '-',
                  style: GoogleFonts.poppins(
                    color:
                        isLatest
                            ? Colors.white
                            : DesignTokens.textSecondaryDark,
                    fontWeight: isLatest ? FontWeight.w600 : FontWeight.w400,
                    fontSize: isLatest ? 14 : 12,
                  ),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (val / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(
                      overTarget ? Colors.redAccent : color,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Assessment Card ────────────────────────────────────────────
  Widget _buildAssessmentCard(String assessment) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.message_text,
                color: DesignTokens.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Penilaian',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing3),
          Text(
            assessment,
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Savings Suggestions ──────────────────────────────────────
  Widget _buildSuggestionsSection(FiftyThirtyTwentyAnalysis a) {
    final suggestions = FinancialAdvisorService.generateSuggestions(a);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.successColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.lamp_charge,
                color: DesignTokens.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cara Hemat',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing1),
          Text(
            'Kurangi pengeluaran ini untuk menabung lebih banyak',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: DesignTokens.spacing3),
          ...suggestions.map((s) => _buildSuggestionItem(s)),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(SavingsSuggestion s) {
    final isNeeds = s.type == 'needs';
    final color = isNeeds ? Colors.blue : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isNeeds ? Iconsax.shield_tick : Iconsax.heart,
                    size: 14,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.categoryName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Hemat ${CurrencyFormatter.formatRupiah(s.potentialMonthlySavings)}/bln',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.successColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Saat ini ${CurrencyFormatter.formatRupiah(s.currentAmount)} — '
                        'target ${CurrencyFormatter.formatRupiah(s.targetAmount)}',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Row(
              children: [
                Material(
                  color: DesignTokens.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: InkWell(
                    onTap: () => _searchAlternatives(s.categoryName),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.search_normal,
                            size: 13,
                            color: DesignTokens.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cari Alternatif',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: DesignTokens.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: InkWell(
                    onTap: () => _createGoalFromSuggestion(s),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.flag,
                            size: 13,
                            color: DesignTokens.successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Buat Goal',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.successColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAlternatives(String category) async {
    final query = Uri.encodeComponent('$category murah');
    final uri = Uri.parse('https://www.google.com/maps/search/$query');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: silently fail — user can search manually
    }
  }

  Future<void> _createGoalFromSuggestion(SavingsSuggestion s) async {
    final monthlySavings = s.potentialMonthlySavings;
    final yearlyTarget = monthlySavings * 12;
    final targetDate = DateTime.now().add(const Duration(days: 365));

    final initialGoal = <String, dynamic>{
      'name': 'Hemat ${s.categoryName}',
      'monthly_target': monthlySavings,
      'target_amount': yearlyTarget,
      'target_date': DateFormat('yyyy-MM-dd').format(targetDate),
      'goal_type': 'other',
    };

    if (!mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddGoalModal(initialGoal: initialGoal),
    );

    if (result == true && mounted) {
      ErrorHandlerService.showSuccessSnackbar(
        context,
        'Goal berhasil dibuat! Pantau progres di menu Goals.',
      );
    }
  }

  // ─── Category Breakdown ────────────────────────────────────────
  Widget _buildCategoryBreakdown({
    required String title,
    required IconData icon,
    required Color color,
    required List<CategoryBreakdown> categories,
    required double total,
    required double target,
    required double gap,
  }) {
    final overBudget = gap > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.formatRupiah(total),
                style: GoogleFonts.poppins(
                  color: overBudget ? Colors.redAccent : Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing1),
          Row(
            children: [
              Text(
                'Batas: ${CurrencyFormatter.formatRupiah(target)}',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                overBudget
                    ? 'Lebih ${CurrencyFormatter.formatRupiah(gap)}'
                    : 'Sisa ${CurrencyFormatter.formatRupiah(gap.abs())}',
                style: GoogleFonts.poppins(
                  color: overBudget ? Colors.redAccent : Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing2),
          ...categories
              .take(6)
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: GoogleFonts.poppins(
                            color: DesignTokens.textSecondaryDark,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          CurrencyFormatter.formatRupiah(c.amount),
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${c.percentOfIncome.toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            color: DesignTokens.textSecondaryDark,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (categories.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${categories.length - 6} kategori lainnya',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Goal Run-Rates ────────────────────────────────────────────
  Widget _buildGoalSection(FiftyThirtyTwentyAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.flag, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Progres Goals',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing3),
          ...a.goalRunRates.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${g.progressPercent.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color:
                              g.progressPercent >= 100
                                  ? Colors.green
                                  : Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacing1),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (g.progressPercent / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(
                        g.progressPercent >= 100 ? Colors.green : Colors.amber,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacing1),
                  Row(
                    children: [
                      Text(
                        '${CurrencyFormatter.formatRupiah(g.currentAmount)} / '
                        '${CurrencyFormatter.formatRupiah(g.targetAmount)}',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        g.monthsToGoal >= 0
                            ? '${g.monthsToGoal} bln lagi'
                            : g.monthlyContribution > 0
                            ? 'Tidak sesuai target'
                            : 'Belum ditabung',
                        style: GoogleFonts.poppins(
                          color:
                              g.monthsToGoal >= 0
                                  ? Colors.green
                                  : DesignTokens.textSecondaryDark,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
