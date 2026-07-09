import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';
import 'package:financial_app/widgets/common/offline_indicator.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountService _accountService = getIt<AccountService>();

  bool _isLoading = true;
  String? _errorMessage;
  bool _activeOnly = true;

  List<dynamic> _accounts = [];
  double _totalBalance = 0.0;
  Map<String, double> _balanceByType = {};

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
        _accountService.getAccounts(activeOnly: _activeOnly),
        _accountService.getTotalBalance(),
        _accountService.getTotalBalanceByType(),
      ]);

      if (!mounted) return;

      setState(() {
        _accounts = results[0] as List<dynamic>;
        _totalBalance = results[1] as double;
        _balanceByType = results[2] as Map<String, double>;
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

  Color _getAccountColor(String? color) {
    if (color == null || color.isEmpty) return DesignTokens.primaryColor;
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return DesignTokens.primaryColor;
    }
  }

  IconData _getAccountIcon(String? icon) {
    switch (icon ?? 'wallet') {
      case 'wallet':
        return Iconsax.wallet;
      case 'account_balance':
        return Iconsax.bank;
      case 'phone_android':
        return Iconsax.mobile;
      default:
        return Iconsax.wallet;
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
        heroTag: 'accounts_fab',
        backgroundColor: DesignTokens.primaryColor,
        onPressed: _showAddAccountModal,
        tooltip: 'Tambah Akun',
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations? l10n) {
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
                tooltip: 'Kembali',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                l10n?.account ?? 'Akun',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Saldo',
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatRupiah(_totalBalance.toInt()),
                  style: GoogleFonts.poppins(
                    color: DesignTokens.textPrimaryDark,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_balanceByType.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children:
                        _balanceByType.entries.map((entry) {
                          return Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTypeLabel(entry.key),
                                  style: GoogleFonts.poppins(
                                    color: DesignTokens.textTertiaryDark,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatRupiah(
                                    entry.value.toInt(),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: DesignTokens.textSecondaryDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank';
      case 'e_wallet':
        return 'E-Wallet';
      default:
        return type;
    }
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

    if (_accounts.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        return _buildAccountCard(context, account, l10n);
      },
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    dynamic account,
    AppLocalizations? l10n,
  ) {
    final name = account.name ?? '';
    final type = account.type ?? 'cash';
    final balance = account.balance ?? 0.0;
    final icon = account.icon;
    final color = account.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceDark,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: DesignTokens.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getAccountColor(color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Icon(
              _getAccountIcon(icon),
              color: _getAccountColor(color),
              size: 24,
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
                  _getTypeLabel(type),
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
                CurrencyFormatter.formatRupiah(balance.toInt()),
                style: GoogleFonts.poppins(
                  color: DesignTokens.successColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Edit akun',
                    button: true,
                    child: InkWell(
                      onTap: () => _editAccount(account),
                      child: Icon(
                        Iconsax.edit,
                        size: 16,
                        color: DesignTokens.textSecondaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    label: 'Hapus akun',
                    button: true,
                    child: InkWell(
                      onTap: () => _deleteAccount(account),
                      child: Icon(
                        Iconsax.trash,
                        size: 16,
                        color: DesignTokens.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.wallet, size: 64, color: DesignTokens.textTertiaryDark),
          const SizedBox(height: 16),
          Text(
            l10n?.no_transactions_title ?? 'Belum Ada Akun',
            style: GoogleFonts.poppins(
              color: DesignTokens.textPrimaryDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.no_transactions_subtitle ?? 'Tap + untuk menambah akun baru',
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

  void _showAddAccountModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddAccountModal(onAccountAdded: _loadData);
      },
    );
  }

  void _editAccount(dynamic account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddAccountModal(account: account, onAccountAdded: _loadData);
      },
    );
  }

  Future<void> _deleteAccount(dynamic account) async {
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
            l10n?.confirm_delete_budget ?? 'Yakin ingin menghapus akun ini?',
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
        await _accountService.deleteAccount(account.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.transaction_deleted_successfully ?? 'Akun berhasil dihapus',
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

class _AddAccountModal extends StatefulWidget {
  final dynamic account;
  final VoidCallback onAccountAdded;

  const _AddAccountModal({this.account, required this.onAccountAdded});

  @override
  State<_AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<_AddAccountModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'cash';
  String _selectedIcon = 'wallet';
  String _selectedColor = '#4CAF50';

  final List<Map<String, dynamic>> _types = [
    {'value': 'cash', 'label': 'Cash', 'icon': 'wallet'},
    {'value': 'bank', 'label': 'Bank', 'icon': 'bank'},
    {'value': 'e_wallet', 'label': 'E-Wallet', 'icon': 'mobile'},
  ];

  final List<String> _colors = [
    '#4CAF50',
    '#2196F3',
    '#FF9800',
    '#9C27B0',
    '#F44336',
    '#8B5FBF',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account.name ?? '';
      _balanceController.text = (widget.account.balance ?? 0.0).toString();
      _selectedType = widget.account.type ?? 'cash';
      _selectedIcon = widget.account.icon ?? 'wallet';
      _selectedColor = widget.account.color ?? '#4CAF50';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.account != null;

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
                isEditing ? 'Edit Akun' : l10n?.add ?? 'Tambah Akun',
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
                'Tipe Akun',
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
                            _selectedIcon = type['icon'];
                          });
                        },
                        backgroundColor: DesignTokens.surfaceDark,
                        selectedColor: DesignTokens.primaryColor,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n?.balance ?? 'Saldo',
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
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan saldo';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Saldo harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Warna',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    _colors.map((color) {
                      final isSelected = _selectedColor == color;
                      return Semantics(
                        label: 'Pilih warna',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(color.replaceFirst('#', '0xFF')),
                              ),
                              shape: BoxShape.circle,
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      )
                                      : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAccount,
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
                    isEditing ? 'Simpan' : l10n?.add ?? 'Tambah',
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

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final accountService = getIt<AccountService>();
      final accountData = {
        'name': _nameController.text,
        'type': _selectedType,
        'icon': _selectedIcon,
        'color': _selectedColor,
        'balance': double.tryParse(_balanceController.text) ?? 0.0,
        'currency': 'IDR',
      };

      if (widget.account != null) {
        await accountService.updateAccount(widget.account.id, accountData);
      } else {
        await accountService.createAccount(
          AccountModel(
            id: 'account_${DateTime.now().millisecondsSinceEpoch}',
            name: _nameController.text,
            type: _selectedType,
            icon: _selectedIcon,
            color: _selectedColor,
            balance: double.tryParse(_balanceController.text) ?? 0.0,
            createdAt: DateTime.now(),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onAccountAdded();
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
