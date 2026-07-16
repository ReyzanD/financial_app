import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/models/split_model.dart';
import 'package:financial_app/services/expense_split_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class AddSplitModal extends StatefulWidget {
  final VoidCallback onSplitAdded;
  const AddSplitModal({super.key, required this.onSplitAdded});

  @override
  State<AddSplitModal> createState() => _AddSplitModalState();
}

class _AddSplitModalState extends State<AddSplitModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _amountCtl = TextEditingController();
  final _friendCtl = TextEditingController();

  @override
  void dispose() {
    _nameCtl.dispose();
    _amountCtl.dispose();
    _friendCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
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
              const SizedBox(height: DesignTokens.spacing5),
              Text(
                'Tambah Split',
                style: GoogleFonts.poppins(
                  color: DesignTokens.textPrimaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing5),
              TextFormField(
                controller: _nameCtl,
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
                validator: (v) => (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: DesignTokens.spacing4),
              TextFormField(
                controller: _amountCtl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: l10n?.amount ?? 'Jumlah',
                  labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Jumlah tidak boleh kosong' : null,
              ),
              const SizedBox(height: DesignTokens.spacing4),
              TextFormField(
                controller: _friendCtl,
                style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: 'Nama Teman',
                  labelStyle: GoogleFonts.poppins(color: DesignTokens.textSecondaryDark),
                  filled: true,
                  fillColor: DesignTokens.surfaceDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    borderSide: BorderSide(color: DesignTokens.borderDark),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Nama teman tidak boleh kosong' : null,
              ),
              const SizedBox(height: DesignTokens.spacing6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
                  ),
                  child: Text(
                    l10n?.add ?? 'Tambah',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacing5),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await getIt<ExpenseSplitService>().createSplit(
        SplitModel(
          id: 'split_${DateTime.now().millisecondsSinceEpoch}',
          transactionId: '',
          participantName: _nameCtl.text,
          amount: double.tryParse(_amountCtl.text) ?? 0.0,
          createdAt: DateTime.now(),
          isSettled: false,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSplitAdded();
    } catch (e) {
      if (!mounted) return;
      ErrorHandlerService.showErrorSnackbar(context, ErrorHandlerService.getUserFriendlyMessage(e));
    }
  }
}
