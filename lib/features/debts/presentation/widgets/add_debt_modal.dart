import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/services/debt_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class AddDebtModal extends StatefulWidget {
  final VoidCallback onDebtAdded;
  const AddDebtModal({super.key, required this.onDebtAdded});

  @override
  State<AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends State<AddDebtModal> {
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
        left: 20, right: 20, top: 20,
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
                  width: 40, height: 4,
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
                  fontSize: 18, fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: l10n?.name ?? 'Nama',
                  labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                  filled: true, fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              Text('Tipe Hutang', style: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: _types.map((type) {
                final isSelected = _selectedType == type['value'];
                return ChoiceChip(
                  label: Text(type['label'], style: GoogleFonts.poppins(color: isSelected ? Colors.white : DesignTokens.textSecondaryDark, fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedType = type['value']),
                  backgroundColor: DesignTokens.surfaceDark,
                  selectedColor: DesignTokens.primaryColor,
                );
              }).toList()),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: l10n?.original_amount ?? 'Jumlah Awal',
                  labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                  filled: true, fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Jumlah tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: l10n?.interest_rate ?? 'Bunga (%)',
                  labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                  filled: true, fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty && double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Bunga harus berupa angka';
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
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    ),
                  ),
                  child: Text(
                    l10n?.add ?? 'Tambah',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
      await debtService.addDebt(DebtModel(
        id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        originalAmount: double.tryParse(_amountController.text) ?? 0.0,
        currentBalance: double.tryParse(_amountController.text) ?? 0.0,
        interestRate: double.tryParse(_interestController.text) ?? 0.0,
        type: _selectedType,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      ));
      if (!mounted) return;
      Navigator.pop(context);
      widget.onDebtAdded();
    } catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
    }
  }
}
