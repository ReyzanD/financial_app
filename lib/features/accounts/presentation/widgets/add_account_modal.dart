import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/models/account_model.dart';
import 'package:financial_app/services/account_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';

/// Modal bottom sheet for adding or editing an account.
class AddAccountModal extends StatefulWidget {
  final AccountModel? account;
  final VoidCallback onAccountAdded;

  const AddAccountModal({
    super.key,
    this.account,
    required this.onAccountAdded,
  });

  @override
  State<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<AddAccountModal> {
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
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _selectedType = widget.account!.type;
      _selectedIcon = widget.account!.icon ?? 'wallet';
      _selectedColor = widget.account!.color ?? '#4CAF50';
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
                isEditing
                    ? (l10n?.edit_account ?? 'Edit Akun')
                    : (l10n?.add ?? 'Tambah Akun'),
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
                    return l10n?.enter_balance ?? 'Masukkan saldo';
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
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
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
                    isEditing
                        ? (l10n?.save ?? 'Simpan')
                        : (l10n?.add ?? 'Tambah'),
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
        await accountService.updateAccount(widget.account!.id, accountData);
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
      ErrorHandlerService.showErrorSnackbar(
        context,
        ErrorHandlerService.getUserFriendlyMessage(e),
      );
    }
  }
}
