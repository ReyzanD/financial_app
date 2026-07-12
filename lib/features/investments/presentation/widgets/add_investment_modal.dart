import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/models/investment_model.dart';
import 'package:financial_app/services/investment_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class AddInvestmentModal extends StatefulWidget {
  final VoidCallback onInvestmentAdded;
  const AddInvestmentModal({super.key, required this.onInvestmentAdded});

  @override
  State<AddInvestmentModal> createState() => _AddInvestmentModalState();
}

class _AddInvestmentModalState extends State<AddInvestmentModal> {
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
                l10n?.add_investment ?? 'Tambah Investasi',
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
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'Nama tidak boleh kosong'
                            : null,
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
                children:
                    _types.map((t) {
                      final sel = _selectedType == t['value'];
                      return ChoiceChip(
                        label: Text(
                          t['label'],
                          style: GoogleFonts.poppins(
                            color:
                                sel
                                    ? Colors.white
                                    : DesignTokens.textSecondaryDark,
                            fontSize: 12,
                          ),
                        ),
                        selected: sel,
                        onSelected:
                            (_) => setState(() => _selectedType = t['value']),
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
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textPrimaryDark,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n?.amount ?? 'Jumlah',
                        labelStyle: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                        ),
                        filled: true,
                        fillColor: DesignTokens.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: DesignTokens.borderDark,
                          ),
                        ),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? (l10n?.amount_required ??
                                      'Jumlah tidak boleh kosong')
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _buyPriceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        color: DesignTokens.textPrimaryDark,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Harga Beli',
                        labelStyle: GoogleFonts.poppins(
                          color: DesignTokens.textSecondaryDark,
                        ),
                        filled: true,
                        fillColor: DesignTokens.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusMedium,
                          ),
                          borderSide: BorderSide(
                            color: DesignTokens.borderDark,
                          ),
                        ),
                      ),
                      validator:
                          (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Harga tidak boleh kosong'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPriceController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: 'Harga Saat Ini',
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
                validator:
                    (v) =>
                        (v == null || v.isEmpty)
                            ? 'Harga tidak boleh kosong'
                            : null,
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

  Future<void> _saveInvestment() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await getIt<InvestmentService>().addInvestment(
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
      ErrorHandlerService.showErrorSnackbar(
        context,
        ErrorHandlerService.getUserFriendlyMessage(e),
      );
    }
  }
}
