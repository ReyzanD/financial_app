import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/models/debt_model.dart';
import 'package:financial_app/services/debt_service.dart';
import 'package:financial_app/core/di/service_locator.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';
import 'package:financial_app/l10n/app_localizations.dart';

class RecordPaymentModal extends StatefulWidget {
  final DebtModel debt;
  final VoidCallback onPaymentRecorded;
  const RecordPaymentModal({
    super.key,
    required this.debt,
    required this.onPaymentRecorded,
  });

  @override
  State<RecordPaymentModal> createState() => _RecordPaymentModalState();
}

class _RecordPaymentModalState extends State<RecordPaymentModal> {
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
            widget.debt.name,
            style: GoogleFonts.poppins(
              color: DesignTokens.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: DesignTokens.textPrimaryDark),
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
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return l10n?.amount_required ?? 'Masukkan jumlah';
              if (double.tryParse(v.replaceAll(',', '.')) == null)
                return l10n?.amount_must_be_number ??
                    'Jumlah harus berupa angka';
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
      ErrorHandlerService.showErrorSnackbar(
        context,
        ErrorHandlerService.getUserFriendlyMessage(e),
      );
    }
  }
}
