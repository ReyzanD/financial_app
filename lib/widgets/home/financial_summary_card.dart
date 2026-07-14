import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/financial_calculator.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:financial_app/utils/responsive_helper.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money2/money2.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/date_picker_helper.dart';
import 'package:financial_app/core/di/service_locator.dart';

class FinancialSummaryCard extends StatefulWidget {
  const FinancialSummaryCard({super.key});

  @override
  State<FinancialSummaryCard> createState() => _FinancialSummaryCardState();

  static void refresh(BuildContext context) {
    final state = context.findAncestorStateOfType<_FinancialSummaryCardState>();
    state?.refreshSummary();
  }
}

class _FinancialSummaryCardState extends State<FinancialSummaryCard>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = getIt<ApiService>();
  final FinancialCalculator _calculator = FinancialCalculator();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  double _inflationRate = 3.5; // Default Indonesia inflation rate
  double _taxRate = 15.0; // Default average tax rate

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Delay initial load slightly to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      _loadFinancialSummary();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _inflationRate = prefs.getDouble('inflation_rate') ?? 3.5;
      _taxRate = prefs.getDouble('tax_rate') ?? 15.0;
    });
  }

  Future<void> _loadFinancialSummary() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final summary = await _apiService.getFinancialSummary(
        year: _selectedDate.year,
        month: _selectedDate.month,
      );

      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
          _errorMessage = null;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _isLoading = false;
          _errorMessage =
              l10n?.failed_to_load_transactions ??
              'Gagal memuat data. Tap untuk coba lagi.';
        });
      }
    }
  }

  void _showMonthPicker() async {
    final DateTime? picked = await DatePickerHelper.showDarkDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
      });
      _loadFinancialSummary();
    }
  }

  void refreshSummary() {
    _loadFinancialSummary();
  }

  /// Shimmer skeleton while data loads (replaces old spinner)
  Widget _buildShimmerPlaceholder() {
    return Container(
      height: ResponsiveHelper.cardHeight(context, 200),
      padding: ResponsiveHelper.padding(context, multiplier: 1.25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DesignTokens.primaryColor, Color(0xFF6A3093)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 20),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title placeholder
            Container(
              height: 12,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
            // Balance placeholder
            Container(
              height: 32,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              ),
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
            // Income / Expense row placeholders
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: ResponsiveHelper.cardHeight(context, 72),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.borderRadius(context, 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: ResponsiveHelper.horizontalSpacing(context, 12),
                ),
                Expanded(
                  child: Container(
                    height: ResponsiveHelper.cardHeight(context, 72),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.borderRadius(context, 12),
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

  @override
  void didUpdateWidget(FinancialSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget is rebuilt with new key
    if (widget.key != oldWidget.key) {
      LoggerService.debug(
        '[FinancialSummaryCard] Widget key changed, reloading data',
      );
      _loadFinancialSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DataRefreshNotification>(
      onNotification: (notification) {
        LoggerService.debug(
          'FinancialSummaryCard received refresh notification',
        );
        _loadFinancialSummary();
        return true;
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return _buildShimmerPlaceholder();
    }

    if (_errorMessage != null) {
      return GestureDetector(
        onTap: _loadFinancialSummary,
        child: Container(
          height: ResponsiveHelper.cardHeight(context, 200),
          padding: ResponsiveHelper.padding(context, multiplier: 1.25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DesignTokens.primaryColor, Color(0xFF6A3093)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.borderRadius(context, 20),
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: ResponsiveHelper.iconSize(context, 48),
                ),
                SizedBox(height: ResponsiveHelper.verticalSpacing(context, 12)),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: ResponsiveHelper.fontSize(context, 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final Map<String, dynamic> summaries = _summary?['summary'] ?? {};
    final income =
        (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ?? 0.0;
    final expense =
        (summaries['expense'] as Map<String, dynamic>?)?['total_amount'] ?? 0.0;

    // Use FinancialCalculator for accurate balance calculation
    final incomeDouble = (income is num) ? income.toDouble() : 0.0;
    final expenseDouble = (expense is num) ? expense.toDouble() : 0.0;

    final balanceData = _calculator.calculateBalance(
      income: incomeDouble,
      expenses: expenseDouble,
    );

    // Handle Money object or double for backward compatibility
    final balanceMoney = balanceData['balance'] as Money?;
    final balanceAmount =
        balanceMoney != null
            ? balanceMoney.minorUnits.toDouble()
            : (balanceData['balanceAmount'] as double? ?? 0.0);
    final actualBalance = balanceAmount;
    final balance =
        actualBalance < 0 ? 0.0 : actualBalance; // Display as 0 if negative
    final isNegative = balanceData['isNegative'] as bool;
    final warning = balanceData['warning'] as String?;

    // Calculate savings rate
    final savingsRate = _calculator.calculateSavingsRate(
      income: incomeDouble,
      expenses: expenseDouble,
    );

    // Calculate financial health score with inflation and tax rates
    final healthScore = _calculator.calculateFinancialHealthScore(
      income: incomeDouble,
      expenses: expenseDouble,
      savings: actualBalance,
      inflationRate: _inflationRate,
      taxRate: _taxRate,
    );

    LoggerService.debug(
      'Financial summary calculated',
      error: {
        'income': income,
        'expense': expense,
        'balance': balance,
        'actualBalance': actualBalance,
      },
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: ResponsiveHelper.padding(context, multiplier: 1.25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [DesignTokens.primaryColor, Color(0xFF6A3093)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.borderRadius(context, 20),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Month selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo Bulan Ini',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: ResponsiveHelper.fontSize(context, 14),
                  ),
                ),
                GestureDetector(
                  onTap: _showMonthPicker,
                  child: Container(
                    padding: ResponsiveHelper.symmetricPadding(
                      context,
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.borderRadius(context, 20),
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: ResponsiveHelper.fontSize(context, 12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveHelper.horizontalSpacing(context, 4),
                        ),
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: ResponsiveHelper.iconSize(context, 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
            Text(
              CurrencyFormatter.formatRupiah(balance),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: ResponsiveHelper.fontSize(context, 28),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isNegative && warning != null) ...[
              SizedBox(height: ResponsiveHelper.verticalSpacing(context, 8)),
              Container(
                padding: ResponsiveHelper.symmetricPadding(
                  context,
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.borderRadius(context, 12),
                  ),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      color: Colors.red,
                      size: ResponsiveHelper.iconSize(context, 16),
                    ),
                    SizedBox(
                      width: ResponsiveHelper.horizontalSpacing(context, 6),
                    ),
                    Flexible(
                      child: Text(
                        warning,
                        style: GoogleFonts.poppins(
                          color: Colors.red[300],
                          fontSize: ResponsiveHelper.fontSize(context, 11),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 20)),

            // Income vs Expense
            Row(
              children: [
                Expanded(
                  child: _buildFinanceItem(
                    title: l10n?.income ?? 'Pemasukan',
                    amount: CurrencyFormatter.formatRupiah(income),
                    color: DesignTokens.successColor,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                SizedBox(
                  width: ResponsiveHelper.horizontalSpacing(context, 12),
                ),
                Expanded(
                  child: _buildFinanceItem(
                    title: l10n?.expense ?? 'Pengeluaran',
                    amount: CurrencyFormatter.formatRupiah(expense),
                    color: DesignTokens.errorColor,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
              ],
            ),

            // Savings Rate & Health Score
            SizedBox(height: ResponsiveHelper.verticalSpacing(context, 16)),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    title: 'Tingkat Tabungan',
                    value: '${savingsRate.toStringAsFixed(1)}%',
                    color:
                        savingsRate >= 20
                            ? DesignTokens.successColor
                            : savingsRate >= 10
                            ? DesignTokens.warningColor
                            : DesignTokens.errorColor,
                    icon: Iconsax.wallet_3,
                  ),
                ),
                SizedBox(
                  width: ResponsiveHelper.horizontalSpacing(context, 12),
                ),
                Expanded(
                  child: _buildMetricItem(
                    title: 'Skor Kesehatan',
                    value: (healthScore['score'] as double).toStringAsFixed(0),
                    color:
                        (healthScore['score'] as double) >= 80
                            ? DesignTokens.successColor
                            : (healthScore['score'] as double) >= 60
                            ? DesignTokens.warningColor
                            : DesignTokens.errorColor,
                    icon: Iconsax.health,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: ResponsiveHelper.symmetricPadding(
        context,
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 12),
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveHelper.iconSize(context, 16),
              ),
              SizedBox(width: ResponsiveHelper.horizontalSpacing(context, 6)),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: ResponsiveHelper.fontSize(context, 10),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 4)),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: ResponsiveHelper.fontSize(context, 14),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceItem({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Semantics(
      label: '$title: $amount',
      excludeSemantics: true,
      child: Container(
        padding: ResponsiveHelper.padding(context, multiplier: 0.75),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.borderRadius(context, 12),
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: ResponsiveHelper.padding(context, multiplier: 0.625),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveHelper.iconSize(context, 22),
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 10)),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: ResponsiveHelper.fontSize(context, 11),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveHelper.verticalSpacing(context, 6)),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: ResponsiveHelper.fontSize(context, 13),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      ),
    );
  }
}

