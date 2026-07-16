import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:financial_app/services/exchange_rate_service.dart';
import 'package:financial_app/services/financial_advisor_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';
import 'package:financial_app/widgets/common/responsive_content.dart';
import 'package:financial_app/widgets/goals/add_goal_modal.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/services/error_handler_service.dart';

/// German Student Finance Planner — DAAD narrative feature.
///
/// Shows the Sperrkonto (blocked account) requirement in both EUR and IDR,
/// a live EUR ⇄ IDR converter, and the user's savings progress toward the goal.
/// Reuses [ExchangeRateService] and [FinancialAdvisorService] — no new
/// database tables or services required.
class GermanFinanceScreen extends StatefulWidget {
  const GermanFinanceScreen({super.key});

  @override
  State<GermanFinanceScreen> createState() => _GermanFinanceScreenState();
}

class _GermanFinanceScreenState extends State<GermanFinanceScreen> {
  final ExchangeRateService _exchangeService = getIt<ExchangeRateService>();
  final FinancialAdvisorService _advisorService = getIt<FinancialAdvisorService>();

  // 2026 Sperrkonto requirement (tied to BAföG §13, reviewed annually)
  static const double _sperrRequiredEur = 11904.0;
  static const double _sperrMonthlyEur = 992.0;

  double? _rateEurToIdr;
  double _monthlySavings = 0;
  double _monthlyIncome = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Converter state
  final TextEditingController _eurController = TextEditingController();
  final TextEditingController _idrController = TextEditingController();
  bool _isUpdatingEur = false;
  bool _isUpdatingIdr = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _eurController.dispose();
    _idrController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rate = await _exchangeService.getExchangeRate('EUR', 'IDR');
      final now = DateTime.now();
      final analysis = await _advisorService.analyzeForPeriod(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      );

      if (!mounted) return;
      setState(() {
        _rateEurToIdr = rate;
        _monthlySavings = analysis.savings;
        _monthlyIncome = analysis.monthlyIncome;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('[GermanFinance] Error loading data', error: e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data. Periksa koneksi dan coba lagi.';
      });
    }
  }

  // ── Converters ──────────────────────────────────────────────────

  void _onEurChanged(String value) {
    if (_isUpdatingEur) return;
    final eur = double.tryParse(value.replaceAll(',', '.'));
    if (eur == null || _rateEurToIdr == null) return;
    _isUpdatingIdr = true;
    _idrController.text = (eur * _rateEurToIdr!).toStringAsFixed(0);
    _isUpdatingIdr = false;
  }

  void _onIdrChanged(String value) {
    if (_isUpdatingIdr) return;
    final idr = double.tryParse(value.replaceAll(',', '.'));
    if (idr == null || _rateEurToIdr == null) return;
    _isUpdatingEur = true;
    _eurController.text = (idr / _rateEurToIdr!).toStringAsFixed(2);
    _isUpdatingEur = false;
  }

  double get _requiredInIdr => _rateEurToIdr != null ? _sperrRequiredEur * _rateEurToIdr! : 0;
  double get _monthlyInIdr => _rateEurToIdr != null ? _sperrMonthlyEur * _rateEurToIdr! : 0;
  int get _monthsToGoal =>
      _monthlySavings > 0 ? (_sperrRequiredEur * (_rateEurToIdr ?? 17500) / _monthlySavings).ceil() : -1;

  String get _assessmentText {
    if (_monthlyIncome <= 0) return 'Belum ada data pemasukan bulan ini.';
    if (_monthlySavings >= _requiredInIdr) {
      return 'Luar biasa! Tabungan Anda sudah mencapai target Sperrkonto.';
    }
    if (_monthlySavings > 0) {
      final months = _monthsToGoal;
      if (months <= 12) {
        return 'Dengan tabungan Rp ${CurrencyFormatter.formatRupiah(_monthlySavings.toInt())}/bulan, '
            'Anda bisa mencapai €11.904 dalam $months bulan.';
      } else if (months <= 24) {
        return 'Target €11.904 bisa dicapai dalam $months bulan. '
            'Coba tingkatkan tabungan bulanan agar lebih cepat.';
      }
      return 'Dengan tabungan saat ini, butuh $months bulan. '
          'Pertimbangkan menaikkan jumlah tabungan per bulan.';
    }
    return 'Belum ada tabungan yang tercatat. Mulai menabung untuk studi Anda!';
  }

  // ── Actions ─────────────────────────────────────────────────────

  Future<void> _createDaadGoal() async {
    final idrTarget = _requiredInIdr.toInt();
    final monthlyTarget = _monthlyInIdr.toInt();

    final goal = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddGoalModal(
            initialGoal: {
              'name': 'Sperrkonto Studi Jerman',
              'target_amount': idrTarget,
              'monthly_target': monthlyTarget,
              'target_date': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
              'type': 'education',
            },
          ),
    );

    if (goal != null && mounted) {
      ErrorHandlerService.showSuccessSnackbar(context, 'Goal Sperrkonto berhasil dibuat!');
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ErrorHandlerService.showSuccessSnackbar(context, '$label disalin ke clipboard');
    }
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      appBar: AppBar(
        backgroundColor: DesignTokens.backgroundDark,
        title: Text(
          'Perencanaan Studi Jerman',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveContent(child: Column(children: [const OfflineIndicator(), Expanded(child: _buildBody())])),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: DesignTokens.primaryColor));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 48, color: Colors.orange),
              const SizedBox(height: DesignTokens.spacing4),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: DesignTokens.spacing4),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Iconsax.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: DesignTokens.spacing5),
            _buildSperrkontoCard(),
            const SizedBox(height: DesignTokens.spacing5),
            _buildSavingsProgressCard(),
            const SizedBox(height: DesignTokens.spacing5),
            _buildConverterCard(),
          ],
        ),
      ),
    );
  }

  // ── Info banner ─────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.primaryColor.withValues(alpha: 0.15),
            DesignTokens.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.info_circle, color: DesignTokens.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sperrkonto (rekening terblokir) adalah syarat visa pelajar Jerman. '
              'Dana €11.904 (2026) disetor di muka dan dicairkan €992/bulan.',
              style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sperrkonto Card ─────────────────────────────────────────────

  Widget _buildSperrkontoCard() {
    return _Card(
      title: 'Informasi Sperrkonto',
      icon: Iconsax.shield_tick,
      children: [
        _buildAmountRow(
          label: 'Jumlah Dibutuhkan',
          eurAmount: '€ ${_formatEur(_sperrRequiredEur)}',
          idrAmount: 'Rp ${CurrencyFormatter.formatRupiah(_requiredInIdr.toInt())}',
          primary: true,
        ),
        const Divider(color: DesignTokens.borderDark, height: 24),
        _buildAmountRow(
          label: 'Pencairan Bulanan',
          eurAmount: '€ ${_formatEur(_sperrMonthlyEur)}',
          idrAmount: 'Rp ${CurrencyFormatter.formatRupiah(_monthlyInIdr.toInt())}',
          primary: false,
        ),
        const SizedBox(height: DesignTokens.spacing3),
        Row(
          children: [
            const Icon(Iconsax.calendar, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              'Berlaku untuk 2026 (ditinjau setiap tahun)',
              style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountRow({
    required String label,
    required String eurAmount,
    required String idrAmount,
    required bool primary,
  }) {
    final color = primary ? Colors.white : Colors.grey[300];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: DesignTokens.spacing2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              eurAmount,
              style: GoogleFonts.poppins(color: color, fontSize: primary ? 28 : 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IconButton(
                icon: const Icon(Iconsax.copy, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Salin EUR',
                onPressed: () => _copyToClipboard(eurAmount, 'Nilai EUR'),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                idrAmount,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: primary ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IconButton(
                icon: const Icon(Iconsax.copy, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Salin IDR',
                onPressed: () => _copyToClipboard(idrAmount, 'Nilai IDR'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatEur(double value) {
    final formatter = NumberFormat('#,##0', 'id');
    return formatter.format(value);
  }

  // ── Savings Progress Card ───────────────────────────────────────

  Widget _buildSavingsProgressCard() {
    final progress = _requiredInIdr > 0 ? (_monthlySavings * 12 / _requiredInIdr * 100).clamp(0, 100) : 0.0;

    return _Card(
      title: 'Progres Tabungan Saya',
      icon: Iconsax.chart_2,
      children: [
        // Assessment text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
          child: Row(
            children: [
              Icon(
                _monthlySavings >= _requiredInIdr
                    ? Iconsax.tick_circle
                    : _monthlySavings > 0
                    ? Iconsax.clock
                    : Iconsax.info_circle,
                color:
                    _monthlySavings >= _requiredInIdr
                        ? DesignTokens.successColor
                        : _monthlySavings > 0
                        ? Colors.amber
                        : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _assessmentText,
                  style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacing4),

        // Stats row
        Row(
          children: [
            _buildStatItem(
              icon: Iconsax.money_send,
              label: 'Tabungan/Bulan',
              value: 'Rp ${CurrencyFormatter.formatRupiah(_monthlySavings.toInt())}',
              valueColor: DesignTokens.successColor,
            ),
            const SizedBox(width: 16),
            _buildStatItem(
              icon: Iconsax.clock,
              label: 'Estimasi Tercapai',
              value: _monthsToGoal > 0 ? '${_monthsToGoal} bulan' : '—',
              valueColor:
                  _monthsToGoal <= 12
                      ? DesignTokens.successColor
                      : _monthsToGoal <= 24
                      ? Colors.amber
                      : Colors.red[300]!,
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacing4),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: DesignTokens.surfaceDark,
            valueColor: const AlwaysStoppedAnimation(DesignTokens.primaryColor),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${progress.toStringAsFixed(1)}% dari target 1 tahun',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11),
          ),
        ),
        const SizedBox(height: DesignTokens.spacing4),

        // Create goal button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _createDaadGoal,
            icon: const Icon(Iconsax.flag, size: 18),
            label: Text('Buat Goal Sperrkonto', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.primaryColor,
              side: const BorderSide(color: DesignTokens.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.surfaceDark,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: valueColor, size: 18),
            const SizedBox(height: DesignTokens.spacing2),
            Text(value, style: GoogleFonts.poppins(color: valueColor, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Converter Card ──────────────────────────────────────────────

  Widget _buildConverterCard() {
    return _Card(
      title: 'Konverter EUR/IDR',
      icon: Iconsax.convert,
      children: [
        if (_rateEurToIdr != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '1 EUR = Rp ${CurrencyFormatter.formatRupiah(_rateEurToIdr!.toInt())}',
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _buildCurrencyField(
                controller: _eurController,
                label: 'Euro (EUR)',
                symbol: '€',
                hint: '0.00',
                onChanged: _onEurChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Iconsax.arrow_right_2, color: Colors.grey[500], size: 20),
            ),
            Expanded(
              child: _buildCurrencyField(
                controller: _idrController,
                label: 'Rupiah (IDR)',
                symbol: 'Rp',
                hint: '0',
                onChanged: _onIdrChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacing3),
        // Quick converter chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickChip('€992', 'Bulanan'),
            _buildQuickChip('€5.000', null),
            _buildQuickChip('€11.904', 'Sperrkonto'),
            _buildQuickChip('€20.000', null),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String label,
    required String symbol,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
        prefixText: '$symbol ',
        prefixStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[700]),
        filled: true,
        fillColor: DesignTokens.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: BorderSide(color: DesignTokens.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: BorderSide(color: DesignTokens.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: const BorderSide(color: DesignTokens.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildQuickChip(String eurAmount, String? label) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(eurAmount, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 10)),
          ],
        ],
      ),
      onPressed: () {
        final eur = double.tryParse(eurAmount.replaceAll('.', '').replaceAll(',', '.'));
        if (eur != null) {
          _eurController.text = eur.toStringAsFixed(2);
        }
      },
      backgroundColor: DesignTokens.surfaceDark,
      side: BorderSide(color: DesignTokens.borderDark),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

// ── Reusable card wrapper ─────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Card({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DesignTokens.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing4),
          ...children,
        ],
      ),
    );
  }
}
