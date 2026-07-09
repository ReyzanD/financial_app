import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/net_worth_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  final NetWorthService _netWorthService = NetWorthService();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _netWorthData = {};
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic> _trend = {};

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
        _netWorthService.calculateNetWorth(),
        _netWorthService.getHistory(limit: 30),
        _netWorthService.getNetWorthTrend(),
      ]);

      if (!mounted) return;

      setState(() {
        _netWorthData = results[0] as Map<String, dynamic>;
        _history = results[1] as List<Map<String, dynamic>>;
        _trend = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: DesignTokens.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            const OfflineIndicator(),
            Expanded(
              child: RefreshIndicator(
                color: DesignTokens.primaryColor,
                backgroundColor: DesignTokens.surfaceDark,
                onRefresh: _loadData,
                child: _buildBody(context, l10n),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'net_worth_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: _recordSnapshot,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final netWorth = (_netWorthData['net_worth'] as num?)?.toDouble() ?? 0.0;
    final totalAssets =
        (_netWorthData['total_assets'] as num?)?.toDouble() ?? 0.0;
    final totalLiabilities =
        (_netWorthData['total_liabilities'] as num?)?.toDouble() ?? 0.0;
    final trend = _trend['trend'] ?? 'neutral';
    final change = (_trend['change'] as num?)?.toDouble() ?? 0.0;
    final isPositive = trend == 'up' || change > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Iconsax.arrow_left,
                  color: DesignTokens.textPrimaryDark,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Net Worth',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isPositive
                          ? DesignTokens.successColor
                          : DesignTokens.errorColor)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Iconsax.arrow_up_1 : Iconsax.arrow_down,
                      color:
                          isPositive
                              ? DesignTokens.successColor
                              : DesignTokens.errorColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color:
                            isPositive
                                ? DesignTokens.successColor
                                : DesignTokens.errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceDark,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(color: DesignTokens.borderDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Worth',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(netWorth.toInt()),
                  style: GoogleFonts.poppins(
                    color:
                        netWorth >= 0
                            ? DesignTokens.successColor
                            : DesignTokens.errorColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assets',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textSecondaryDark,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(totalAssets.toInt()),
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textPrimaryDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Liabilities',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textSecondaryDark,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(
                              totalLiabilities.toInt(),
                            ),
                            style: GoogleFonts.poppins(
                              color: DesignTokens.errorColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations? l10n) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(context, l10n);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBreakdown(context, l10n),
        const SizedBox(height: 16),
        _buildHistory(context, l10n),
      ],
    );
  }

  Widget _buildBreakdown(BuildContext context, AppLocalizations? l10n) {
    final assetBreakdown =
        (_netWorthData['asset_breakdown'] as Map?)?.cast<String, double>() ??
        {};
    final liabilityBreakdown =
        (_netWorthData['liability_breakdown'] as Map?)
            ?.cast<String, double>() ??
        {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breakdown',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (assetBreakdown.isNotEmpty) ...[
          Text(
            'Assets',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...assetBreakdown.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceDark,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(color: DesignTokens.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getAssetTypeLabel(entry.key),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textPrimaryDark,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatRupiah(entry.value.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.successColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
        if (liabilityBreakdown.isNotEmpty) ...[
          Text(
            'Liabilities',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...liabilityBreakdown.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceDark,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                border: Border.all(color: DesignTokens.borderDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getLiabilityTypeLabel(entry.key),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textPrimaryDark,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatRupiah(entry.value.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.errorColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildHistory(BuildContext context, AppLocalizations? l10n) {
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History Trend',
          style: GoogleFonts.poppins(
            color: DesignTokens.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceDark,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(color: DesignTokens.borderDark),
          ),
          child: Column(
            children:
                _history.take(7).map((snapshot) {
                  final date = snapshot['snapshot_date'] ?? '';
                  final netWorth =
                      (snapshot['net_worth'] as num?)?.toDouble() ?? 0.0;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: DesignTokens.borderDark,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: GoogleFonts.poppins(
                            color: DesignTokens.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatRupiah(netWorth.toInt()),
                          style: GoogleFonts.poppins(
                            color:
                                netWorth >= 0
                                    ? DesignTokens.successColor
                                    : DesignTokens.errorColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  String _getAssetTypeLabel(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank';
      case 'e_wallet':
        return 'E-Wallet';
      case 'investments':
        return 'Investments';
      default:
        return type;
    }
  }

  String _getLiabilityTypeLabel(String type) {
    switch (type) {
      case 'personal':
        return 'Pinjaman Pribadi';
      case 'mortgage':
        return 'Kredit Rumah';
      case 'student':
        return 'Pinjaman Pendidikan';
      case 'credit_card':
        return 'Kartu Kredit';
      case 'car':
        return 'Kredit Mobil';
      default:
        return type;
    }
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: DesignTokens.errorColor),
          const SizedBox(height: 16),
          Text(
            l10n?.error ?? 'Terjadi kesalahan',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryColor,
            ),
            child: Text(
              l10n?.retry ?? 'Coba Lagi',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _recordSnapshot() async {
    try {
      await _netWorthService.recordSnapshot();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Snapshot recorded'),
          backgroundColor: DesignTokens.successColor,
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: DesignTokens.errorColor,
        ),
      );
    }
  }
}
