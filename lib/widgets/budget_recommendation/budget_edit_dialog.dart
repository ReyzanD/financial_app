import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/utils/design_tokens.dart';

/// Dialog untuk edit persentase budget category
class BudgetEditDialog extends StatelessWidget {
  final String categoryName;
  final int currentPercentage;
  final Function(double) onSave;

  const BudgetEditDialog({
    super.key,
    required this.categoryName,
    required this.currentPercentage,
    required this.onSave,
  });

  static Future<double?> show(
    BuildContext context, {
    required String categoryName,
    required int currentPercentage,
  }) async {
    double? result;
    await showDialog(
      context: context,
      builder:
          (context) => BudgetEditDialog(
            categoryName: categoryName,
            currentPercentage: currentPercentage,
            onSave: (value) {
              result = value;
              Navigator.pop(context);
            },
          ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: currentPercentage.toString(),
    );

    return AlertDialog(
      backgroundColor: DesignTokens.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Edit Persentase',
        style: GoogleFonts.poppins(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryName,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Persentase (%)',
              labelStyle: GoogleFonts.poppins(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: DesignTokens.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '💡 Pastikan total semua persentase = 100%',
            style: GoogleFonts.poppins(color: Colors.orange, fontSize: 11),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final newPercentage = double.tryParse(controller.text);
            if (newPercentage != null &&
                newPercentage > 0 &&
                newPercentage <= 100) {
              onSave(newPercentage);
            } else {
              ErrorHandlerService.showWarningSnackbar(
                context,
                'Masukkan persentase yang valid (1-100)',
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primaryColor,
          ),
          child: Text(
            'Simpan',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
