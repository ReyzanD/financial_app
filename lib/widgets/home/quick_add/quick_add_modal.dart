import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:financial_app/services/api_service.dart';
import 'package:financial_app/services/logger_service.dart';
import 'package:financial_app/utils/formatters.dart';
import 'package:financial_app/utils/form_validators.dart';
import 'package:financial_app/utils/app_refresh.dart';
import 'package:financial_app/l10n/app_localizations.dart';

/// Modal untuk quick add transaction dengan form lengkap
class QuickAddModal extends StatefulWidget {
  final String type;
  final double? presetAmount;
  final String? presetCategoryId;
  final VoidCallback? onTransactionAdded;

  const QuickAddModal({
    super.key,
    required this.type,
    this.presetAmount,
    this.presetCategoryId,
    this.onTransactionAdded,
  });

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  final ApiService _apiService = ApiService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    if (widget.presetAmount != null) {
      _amountController.text = widget.presetAmount!.toInt().toString();
    }
    _selectedCategoryId = widget.presetCategoryId;
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _categories =
              categories
                  .where(
                    (cat) =>
                        cat != null && cat['id'] != null && cat['name'] != null,
                  )
                  .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      LoggerService.error('Error loading categories', error: e);
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.failed_to_load_categories}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _checkBalanceBeforeExpense(double expenseAmount) async {
    try {
      // Get current financial summary
      final summary = await _apiService.getFinancialSummary();
      final summaries = summary['summary'] as Map<String, dynamic>?;

      if (summaries == null) return true; // Allow if we can't check

      final income =
          (summaries['income'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;
      final expense =
          (summaries['expense'] as Map<String, dynamic>?)?['total_amount'] ??
          0.0;
      final currentBalance = income - expense;
      final newBalance = currentBalance - expenseAmount;

      // Minimum balance requirement: 25000
      const double minimumBalance = 25000.0;

      // If balance would go below the minimum, block the transaction
      if (newBalance < minimumBalance) {
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.block, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Saldo Tidak Cukup',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.transaction_rejected_insufficient_balance,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _buildBalanceRow(
                            AppLocalizations.of(context)!.available_balance,
                            currentBalance,
                            Colors.white70,
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceRow(
                            AppLocalizations.of(context)!.minimum_balance,
                            minimumBalance,
                            Colors.orange[300]!,
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceRow(
                            AppLocalizations.of(context)!.expense,
                            expenseAmount,
                            Colors.red[300]!,
                          ),
                          const Divider(color: Colors.grey, height: 20),
                          _buildBalanceRow(
                            AppLocalizations.of(context)!.shortage,
                            (minimumBalance - newBalance).abs(),
                            Colors.red[400]!,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue[300],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.add_income_first,
                              style: GoogleFonts.poppins(
                                color: Colors.blue[300],
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5FBF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.understood,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
        );
        return false; // Block the transaction
      }

      return true; // Balance is fine, proceed
    } catch (e) {
      LoggerService.error('Error checking balance', error: e);
      return true; // Allow transaction if check fails
    }
  }

  Widget _buildBalanceRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          CurrencyFormatter.formatRupiah(amount.abs()),
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _submitTransaction() async {
    // Validate amount
    final amountError = FormValidators.validateAmount(_amountController.text);
    if (amountError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(amountError), backgroundColor: Colors.red),
      );
      return;
    }

    // Validate description (optional but check length if provided)
    final description = _descriptionController.text.trim();
    final descriptionError = FormValidators.validateDescription(description);
    if (descriptionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(descriptionError), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.select_category),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.parse(
      _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
    );

    // Check balance before adding expense
    if (widget.type == 'expense') {
      final shouldContinue = await _checkBalanceBeforeExpense(amount);
      if (!shouldContinue) {
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.addTransaction({
        'description':
            description.isEmpty
                ? widget.type == 'income'
                    ? AppLocalizations.of(context)!.quick_income
                    : AppLocalizations.of(context)!.quick_expense
                : description,
        'amount': amount,
        'type': widget.type,
        'category_id': _selectedCategoryId,
        'date': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        // Trigger immediate refresh
        await AppRefresh.refreshAll(context);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Transaksi berhasil ditambahkan!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onTransactionAdded?.call();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.failed}: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = widget.type == 'income' ? Colors.green : Colors.red;
    final typeIcon =
        widget.type == 'income' ? Iconsax.arrow_down_1 : Iconsax.arrow_up_3;

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
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.type == 'income'
                        ? AppLocalizations.of(context)!.add_income
                        : AppLocalizations.of(context)!.add_expense,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount
            Text(
              'Jumlah',
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
                prefixIcon: Icon(Iconsax.money_4, color: typeColor),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            Text(
              AppLocalizations.of(context)!.category,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingCategories
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5FBF)),
                )
                : _categories.isEmpty
                ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.info_circle,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.no_categories_create_first,
                          style: GoogleFonts.poppins(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: GoogleFonts.poppins(color: Colors.white),
                  hint: Text(
                    AppLocalizations.of(context)!.select_category,
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  decoration: InputDecoration(
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
                  items:
                      _categories.map((category) {
                        final id = category['id']?.toString() ?? '';
                        final name = category['name']?.toString() ?? 'Unknown';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
            const SizedBox(height: 16),

            // Description (optional)
            Text(
              'Deskripsi (Opsional)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.add_description,
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

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: typeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          AppLocalizations.of(context)!.add_transaction,
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
