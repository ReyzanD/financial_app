import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/debt_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final DebtService _debtService = getIt<DebtService>();

  bool _isLoading = true;
  String? _errorMessage;
  bool _activeOnly = true;

  List<dynamic> _debts = [];
  Map<String, dynamic> _summary = {};

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
        _debtService.getDebts(activeOnly: _activeOnly),
        _debtService.getDebtSummary(),
      ]);

      if (!mounted) return;

      setState(() {
        _debts = results[0] as List<dynamic>;
        _summary = results[1] as Map<String, dynamic>;
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

  Color _getDebtTypeColor(String type) {
    switch (type) {
      case 'credit_card':
        return Colors.red;
      case 'mortgage':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'car':
        return Colors.orange;
      case 'personal':
        return Colors.purple;
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
        heroTag: 'debts_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: _showAddDebtModal,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
    final totalDebt = (_summary['total_debt'] as num?)?.toDouble() ?? 0.0;

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
                l10n?.debt ?? 'Hutang',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _activeOnly ? l10n?.active ?? 'Aktif' : l10n?.all ?? 'Semua',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _activeOnly,
                activeThumbColor: DesignTokens.primaryColor,
                inactiveThumbColor: DesignTokens.textTertiaryDark,
                inactiveTrackColor: DesignTokens.borderDark,
                onChanged: (value) {
                  setState(() {
                    _activeOnly = value;
                  });
                  _loadData();
                },
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.total_debt ?? 'Total Hutang',
                        style: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatRupiah(totalDebt.toInt()),
                        style: GoogleFonts.poppins(
                          color: DesignTokens.errorColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignTokens.errorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                  ),
                  child: const Icon(
                    Iconsax.money_send,
                    color: DesignTokens.errorColor,
                    size: 24,
                  ),
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

    if (_debts.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _debts.length,
      itemBuilder: (context, index) {
        final debt = _debts[index];
        return _buildDebtCard(context, debt, l10n);
      },
    );
  }

  Widget _buildDebtCard(
    BuildContext context,
    dynamic debt,
    AppLocalizations? l10n,
  ) {
    final name = debt.name ?? '';
    final type = debt.type ?? 'other';
    final originalAmount = debt.originalAmount ?? 0.0;
    final currentBalance = debt.currentBalance ?? 0.0;
    final interestRate = debt.interestRate ?? 0.0;

    final progress =
        originalAmount > 0
            ? (originalAmount - currentBalance) / originalAmount
            : 0.0;
    final percentage = (progress * 100).clamp(0, 100).toDouble();

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
                  color: _getDebtTypeColor(type).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
                child: Icon(
                  Iconsax.money_send,
                  color: _getDebtTypeColor(type),
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
                      '${l10n?.type ?? 'Tipe'}: ${_getDebtTypeLabel(type)}',
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
                    CurrencyFormatter.formatRupiah(currentBalance.toInt()),
                    style: GoogleFonts.poppins(
                      color: DesignTokens.errorColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${l10n?.interest ?? 'Bunga'}: ${interestRate.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      color: DesignTokens.textTertiaryDark,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n?.original_amount ?? 'Awal'}: ${CurrencyFormatter.formatRupiah(originalAmount.toInt())}',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 11,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}% ${l10n?.progress ?? 'lunas'}',
                style: GoogleFonts.poppins(
                  color: DesignTokens.successColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: DesignTokens.borderDark,
              valueColor: AlwaysStoppedAnimation(DesignTokens.successColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _recordPayment(debt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.successColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                  ),
                  child: Text(
                    l10n?.pay ?? 'Bayar',
                    style: GoogleFonts.poppins(
                      color: DesignTokens.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _deleteDebt(debt),
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

  String _getDebtTypeLabel(String type) {
    switch (type) {
      case 'credit_card':
        return 'Kartu Kredit';
      case 'mortgage':
        return 'Kredit Rumah';
      case 'student':
        return 'Pinjaman Pendidikan';
      case 'car':
        return 'Kredit Mobil';
      case 'personal':
        return 'Pinjaman Pribadi';
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
            Iconsax.money_send,
            size: 64,
            color: DesignTokens.textTertiaryDark,
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.no_debts ?? 'Tidak ada hutang aktif',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.no_obligations_subtitle ?? 'Tap + untuk menambah hutang baru',
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

  void _showAddDebtModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddDebtModal(onDebtAdded: _loadData);
      },
    );
  }

  void _recordPayment(dynamic debt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _RecordPaymentModal(debt: debt, onPaymentRecorded: _loadData);
      },
    );
  }

  Future<void> _deleteDebt(dynamic debt) async {
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
            l10n?.confirm_delete_budget ?? 'Yakin ingin menghapus hutang ini?',
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
        await _debtService.deleteDebt(debt.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.transaction_deleted_successfully ??
                  'Hutang berhasil dihapus',
            ),
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

class _AddDebtModal extends StatefulWidget {
  final VoidCallback onDebtAdded;

  const _AddDebtModal({required this.onDebtAdded});

  @override
  State<_AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends State<_AddDebtModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  String _selectedType = 'personal';

  final List<Map<String, dynamic>> _types = [
    {'value': 'personal', 'label': 'Pinjaman Pribadi'},
    {'value': 'credit_card', 'label': 'Kartu Kredit'},
    {'value': 'mortgage', 'label': 'Kredit Rumah'},
    {'value': 'student', 'label': 'Pinjaman Pendidikan'},
    {'value': 'car', 'label': 'Kredit Mobil'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _interestController.dispose();
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
                l10n?.add ?? 'Tambah Hutang',
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
                  labelStyle: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                  ),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
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
                'Tipe Hutang',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _types.map((type) {
                      final isSelected = _selectedType == type['value'];
                      return ChoiceChip(
                        label: Text(
                          type['label'],
                          style: GoogleFonts.poppins(
                            color:
                                isSelected
                                    ? Colors.white
                                    : DesignTokens.textSecondaryDark,
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
              TextFormField(
                controller: _amountController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n?.original_amount ?? 'Jumlah Awal',
                  labelStyle: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                  ),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n?.interest_rate ?? 'Bunga (%)',
                  labelStyle: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                  ),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Bunga harus berupa angka';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
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

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final debtService = getIt<DebtService>();
      await debtService.addDebt(
        DebtModel(
          id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text,
          originalAmount: double.tryParse(_amountController.text) ?? 0.0,
          currentBalance: double.tryParse(_amountController.text) ?? 0.0,
          interestRate: double.tryParse(_interestController.text) ?? 0.0,
          type: _selectedType,
          startDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onDebtAdded();
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

class _RecordPaymentModal extends StatefulWidget {
  final dynamic debt;
  final VoidCallback onPaymentRecorded;

  const _RecordPaymentModal({
    required this.debt,
    required this.onPaymentRecorded,
  });

  @override
  State<_RecordPaymentModal> createState() => _RecordPaymentModalState();
}

class _RecordPaymentModalState extends State<_RecordPaymentModal> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
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
            l10n?.record_payment ?? 'Catat Pembayaran',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.debt.name ?? '',
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _amountController,
            style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n?.amount ?? 'Jumlah',
              labelStyle: GoogleFonts.poppins(
                color: DesignTokens.textSecondaryDark,
              ),
              filled: true,
              fillColor: DesignTokens.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                borderSide: BorderSide(color: DesignTokens.borderDark),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Masukkan jumlah';
              }
              if (double.tryParse(value.replaceAll(',', '.')) == null) {
                return 'Jumlah harus berupa angka';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _recordPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.successColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
              ),
              child: Text(
                l10n?.pay ?? 'Bayar',
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
    );
  }

  Future<void> _recordPayment() async {
    if (_amountController.text.isEmpty) return;

    try {
      final debtService = getIt<DebtService>();
      await debtService.recordPayment(
        widget.debt.id,
        double.tryParse(_amountController.text) ?? 0.0,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onPaymentRecorded();
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
