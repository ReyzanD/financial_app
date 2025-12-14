import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/error_handler_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/formatters.dart';

class ContributeModal extends StatefulWidget {
  final Map<String, dynamic> goal;

  const ContributeModal({super.key, required this.goal});

  @override
  State<ContributeModal> createState() => _ContributeModalState();
}

class _ContributeModalState extends State<ContributeModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final List<double> _quickAmounts = [50000, 100000, 250000, 500000, 1000000];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _contributeToGoal() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Masukkan jumlah kontribusi',
      );
      return;
    }

    final amount = double.parse(amountText);
    if (amount <= 0) {
      ErrorHandlerService.showWarningSnackbar(
        context,
        'Jumlah harus lebih dari 0',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.addGoalContribution(
        widget.goal['id'].toString(),
        amount,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      if (context.mounted) {
        ErrorHandlerService.showSuccessSnackbar(
          context,
          'Berhasil menambah ${CurrencyFormatter.formatRupiah(amount)}',
        );
      }
    } catch (e) {
      LoggerService.error('Error contributing to goal', error: e);
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (context.mounted) {
        ErrorHandlerService.showErrorSnackbar(
          context,
          ErrorHandlerService.getUserFriendlyMessage(e),
          onRetry: _contributeToGoal,
        );
      }
    }
  }

  void _setQuickAmount(double amount) {
    _amountController.text = CurrencyFormatter.formatRupiah(amount);
  }

  @override
  Widget build(BuildContext context) {
    final currentAmount = (widget.goal['current_amount'] ?? 0).toDouble();
    final targetAmount = (widget.goal['target_amount'] ?? 0).toDouble();
    final remaining = targetAmount - currentAmount;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambah Kontribusi',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Goal Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B5FBF).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.goal['name'] ?? 'Goal',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terkumpul',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(currentAmount),
                            style: GoogleFonts.poppins(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Tersisa',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatRupiah(remaining),
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick Amount Buttons
            Text(
              'Nominal Cepat',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _quickAmounts.map((amount) {
                    return GestureDetector(
                      onTap: () => _setQuickAmount(amount),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5FBF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF8B5FBF).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          CurrencyFormatter.formatRupiah(amount),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF8B5FBF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            // Amount Input
            Text(
              'Jumlah Kontribusi',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Rp 0',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B5FBF),
                    width: 2,
                  ),
                ),
                prefixIcon: const Icon(
                  Iconsax.money_4,
                  color: Color(0xFF8B5FBF),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Note Input (Optional)
            Text(
              'Catatan (Opsional)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tambahkan catatan...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[800]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF8B5FBF),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _contributeToGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5FBF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          'Tambah Kontribusi',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
