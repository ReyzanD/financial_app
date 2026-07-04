import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/investment_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/feature_models.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final InvestmentService _investmentService = getIt<InvestmentService>();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _investments = [];
  Map<String, dynamic> _portfolioSummary = {};

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
        _investmentService.getInvestments(),
        _investmentService.getPortfolioSummary(),
      ]);

      if (!mounted) return;

      setState(() {
        _investments = results[0] as List<dynamic>;
        _portfolioSummary = results[1] as Map<String, dynamic>;
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

  Color _getInvestmentTypeColor(String type) {
    switch (type) {
      case 'stock':
        return Colors.blue;
      case 'mutual_fund':
        return Colors.green;
      case 'crypto':
        return Colors.orange;
      case 'bond':
        return Colors.purple;
      case 'gold':
        return Colors.amber;
      default:
        return DesignTokens.primaryColor;
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
        heroTag: 'investments_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: _showAddInvestmentModal,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final totalValue = (_portfolioSummary['total_value'] as num?)?.toDouble() ?? 0.0;
    final totalPnL = (_portfolioSummary['total_pnl'] as num?)?.toDouble() ?? 0.0;
    final pnlPercentage = (_portfolioSummary['pnl_percentage'] as num?)?.toDouble() ?? 0.0;
    final isPositive = totalPnL >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Iconsax.arrow_left, color: DesignTokens.textPrimaryDark),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.investment ?? 'Investasi',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
                  l10n?.total_amount ?? 'Total Nilai Portofolio',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(totalValue.toInt()),
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
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
                            'P&L',
                            style: GoogleFonts.poppins(
                              color: DesignTokens.textSecondaryDark,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${isPositive ? '+' : ''}${CurrencyFormatter.formatRupiah(totalPnL.toInt())}',
                            style: GoogleFonts.poppins(
                              color: isPositive ? DesignTokens.successColor : DesignTokens.errorColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isPositive ? DesignTokens.successColor : DesignTokens.errorColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${pnlPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          color: isPositive ? DesignTokens.successColor : DesignTokens.errorColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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

    if (_investments.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _investments.length,
      itemBuilder: (context, index) {
        final investment = _investments[index];
        return _buildInvestmentCard(context, investment, l10n);
      },
    );
  }

  Widget _buildInvestmentCard(BuildContext context, dynamic investment, AppLocalizations? l10n) {
    final name = investment.name ?? '';
    final type = investment.type ?? 'other';
    final quantity = investment.quantity ?? 0.0;
    final buyPrice = investment.buyPrice ?? 0.0;
    final currentPrice = investment.currentPrice ?? 0.0;

    final totalCost = quantity * buyPrice;
    final totalValue = quantity * currentPrice;
    final pnl = totalValue - totalCost;
    final pnlPercentage = totalCost > 0 ? (pnl / totalCost) * 100 : 0.0;
    final isPositive = pnl >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getInvestmentTypeColor(type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Icon(
                  Iconsax.chart_success,
                  color: _getInvestmentTypeColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textPrimaryDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_getInvestmentTypeLabel(type)} • ${quantity.toStringAsFixed(2)} unit',
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatRupiah(totalValue.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textPrimaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Iconsax.arrow_up_1 : Iconsax.arrow_down,
                        size: 12,
                        color: isPositive ? DesignTokens.successColor : DesignTokens.errorColor,
                      ),
                      Text(
                        '${pnlPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          color: isPositive ? DesignTokens.successColor : DesignTokens.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Harga Beli', CurrencyFormatter.formatRupiah(buyPrice.toInt())),
              _buildDetailItem(l10n?.current_balance ?? 'Harga Saat Ini', CurrencyFormatter.formatRupiah(currentPrice.toInt())),
              _buildDetailItem('P&L', '${isPositive ? '+' : ''}${CurrencyFormatter.formatRupiah(pnl.toInt())}',
                  valueColor: isPositive ? DesignTokens.successColor : DesignTokens.errorColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _deleteInvestment(investment),
                child: Icon(
                  Iconsax.trash,
                  size: 16,
                  color: DesignTokens.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: DesignTokens.textTertiaryDark,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: valueColor ?? DesignTokens.textSecondaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getInvestmentTypeLabel(String type) {
    switch (type) {
      case 'stock':
        return 'Saham';
      case 'mutual_fund':
        return 'Reksa Dana';
      case 'crypto':
        return 'Kripto';
      case 'bond':
        return 'Obligasi';
      case 'gold':
        return 'Emas';
      default:
        return type;
    }
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.chart_success,
            size: 64,
            color: DesignTokens.textTertiaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada investasi',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + untuk menambah investasi baru',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 64,
            color: DesignTokens.errorColor,
          ),
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

  void _showAddInvestmentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddInvestmentModal(onInvestmentAdded: _loadData);
      },
    );
  }

  Future<void> _deleteInvestment(dynamic investment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DesignTokens.surfaceDark,
          title: Text(
            l10n?.delete ?? 'Hapus',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n?.confirm_delete_budget ?? 'Yakin ingin menghapus investasi ini?',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n?.cancel ?? 'Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                l10n?.delete ?? 'Hapus',
                style: const TextStyle(color: DesignTokens.errorColor),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _investmentService.deleteInvestment(investment.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.transaction_deleted_successfully ?? 'Investasi berhasil dihapus'),
            backgroundColor: DesignTokens.primaryColor,
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
}

class _AddInvestmentModal extends StatefulWidget {
  final VoidCallback onInvestmentAdded;

  const _AddInvestmentModal({required this.onInvestmentAdded});

  @override
  State<_AddInvestmentModal> createState() => _AddInvestmentModalState();
}

class _AddInvestmentModalState extends State<_AddInvestmentModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _currentPriceController = TextEditingController();
  String _selectedType = 'stock';

  final List<Map<String, dynamic>> _types = [
    {'value': 'stock', 'label': 'Saham'},
    {'value': 'mutual_fund', 'label': 'Reksa Dana'},
    {'value': 'crypto', 'label': 'Kripto'},
    {'value': 'bond', 'label': 'Obligasi'},
    {'value': 'gold', 'label': 'Emas'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    _currentPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.textTertiaryDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n?.add ?? 'Tambah Investasi',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: l10n?.name ?? 'Nama',
                  labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Tipe Investasi',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.map((type) {
                  final isSelected = _selectedType == type['value'];
                  return ChoiceChip(
                    label: Text(
                      type['label'],
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : DesignTokens.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = type['value'];
                      });
                    },
                    backgroundColor: DesignTokens.surfaceDark,
                    selectedColor: DesignTokens.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah',
                        labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                        filled: true,
                        fillColor: DesignTokens.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                          borderSide: BorderSide(color: DesignTokens.borderDark),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _buyPriceController,
                      style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga Beli',
                        labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                        filled: true,
                        fillColor: DesignTokens.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                          borderSide: BorderSide(color: DesignTokens.borderDark),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPriceController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga Saat Ini',
                  labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveInvestment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    ),
                  ),
                  child: Text(
                    l10n?.add ?? 'Tambah',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final investmentService = getIt<InvestmentService>();
      await investmentService.addInvestment(
        InvestmentModel(
          id: 'investment_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text,
          type: _selectedType,
          quantity: double.tryParse(_quantityController.text) ?? 0.0,
          buyPrice: double.tryParse(_buyPriceController.text) ?? 0.0,
          currentPrice: double.tryParse(_currentPriceController.text) ?? 0.0,
          buyDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onInvestmentAdded();
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
